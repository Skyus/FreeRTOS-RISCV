/*
    FreeRTOS V8.2.3 - Copyright (C) 2015 Real Time Engineers Ltd.
    All rights reserved

    VISIT http://www.FreeRTOS.org TO ENSURE YOU ARE USING THE LATEST VERSION.

    This file is part of the FreeRTOS distribution and was contributed
    to the project by Technolution B.V. (www.technolution.nl,
    freertos-riscv@technolution.eu) under the terms of the FreeRTOS
    contributors license.

    FreeRTOS is free software; you can redistribute it and/or modify it under
    the terms of the GNU General Public License (version 2) as published by the
    Free Software Foundation >>>> AND MODIFIED BY <<<< the FreeRTOS exception.

    ***************************************************************************
    >>!   NOTE: The modification to the GPL is included to allow you to     !<<
    >>!   distribute a combined work that includes FreeRTOS without being   !<<
    >>!   obliged to provide the source code for proprietary components     !<<
    >>!   outside of the FreeRTOS kernel.                                   !<<
    ***************************************************************************

    FreeRTOS is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
    FOR A PARTICULAR PURPOSE.  Full license text is available on the following
    link: http://www.freertos.org/a00114.html

    ***************************************************************************
     *                                                                       *
     *    FreeRTOS provides completely free yet professionally developed,    *
     *    robust, strictly quality controlled, supported, and cross          *
     *    platform software that is more than just the market leader, it     *
     *    is the industry''s de facto standard.                               *
     *                                                                       *
     *    Help yourself get started quickly while simultaneously helping     *
     *    to support the FreeRTOS project by purchasing a FreeRTOS           *
     *    tutorial book, reference manual, or both:                          *
     *    http://www.FreeRTOS.org/Documentation                              *
     *                                                                       *
    ***************************************************************************

    http://www.FreeRTOS.org/FAQHelp.html - Having a problem?  Start by reading
    the FAQ page "My application does not run, what could be wrong?".  Have you
    defined configASSERT()?

    http://www.FreeRTOS.org/support - In return for receiving this top quality
    embedded software for free we request you assist our global community by
    participating in the support forum.

    http://www.FreeRTOS.org/training - Investing in training allows your team to
    be as productive as possible as early as possible.  Now you can receive
    FreeRTOS training directly from Richard Barry, CEO of Real Time Engineers
    Ltd, and the world's leading authority on the world's leading RTOS.

    http://www.FreeRTOS.org/plus - A selection of FreeRTOS ecosystem products,
    including FreeRTOS+Trace - an indispensable productivity tool, a DOS
    compatible FAT file system, and our tiny thread aware UDP/IP stack.

    http://www.FreeRTOS.org/labs - Where new FreeRTOS products go to incubate.
    Come and try FreeRTOS+TCP, our new open source TCP/IP stack for FreeRTOS.

    http://www.OpenRTOS.com - Real Time Engineers ltd. license FreeRTOS to High
    Integrity Systems ltd. to sell under the OpenRTOS brand.  Low cost OpenRTOS
    licenses offer ticketed support, indemnification and commercial middleware.

    http://www.SafeRTOS.com - High Integrity Systems also provide a safety
    engineered and independently SIL3 certified version for use in safety and
    mission critical applications that require provable dependability.

    1 tab == 4 spaces!
*/


#if __riscv_xlen == 64
# define STORE    sd
# define LOAD     ld
# define REGBYTES 8
#else
# define STORE    sw
# define LOAD     lw
# define REGBYTES 4
#endif

#define EPC 65 // program counter used to store pc during interrupt occurs
#define UIE 0x4 // controls registers responsible for interrupt enable/disable

.equ context_size, 132
/* registers that gcc does not recognise by name for now */
.equ uie, 0x4
.equ ustatus, 0x42
.equ timer, 0xc01

/* Enable interrupts when returning from the handler */
#define UIE_ENABLE_ALL 0xFFFF // enables possible interrupts

.global portSAVE_CONTEXT
.global portRESTORE_CONTEXT
.global TIMER_CMP_INT
.global xPortStartScheduler
.global vPortYield
.global vTaskIncrementTick
.global vPortEndScheduler
.global xExitStack
.global main

.extern extern_isr_lookup_table

.global _start
.org 0
_start:
    j boot_strap

	.align 4
	.globl boot_strap

/* order of these interrupt handlers within the code is critical. DO NOT CHANGE */
.org 0x10
_tn_arch_ecall_vector:
    uret
    nop 
    nop
    nop

/** .section .ebreak_vector: **/
_tn_arch_ebreak_vector:
    uret
    nop
    nop
    nop

/** .section .timer_vector **/
_tn_arch_timer_vector:
    j TIMER_INT_HANDLER 
    nop
    nop
    nop
    nop
    
/** .section .extern_int_vector: **/
_tn_arch_extern_int_vector:
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr
    j execute_external_isr


execute_external_isr:
    addi sp, sp, -context_size

    #store all general purpose registers to the stack
    sw x1, 0(sp)
    sw x3, 8(sp)
    sw x4, 12(sp)
    sw x5, 16(sp)
    sw x6, 20(sp)
    sw x7, 24(sp)
    sw x8, 28(sp)
    sw x9, 32(sp)
    sw x10, 36(sp)
    sw x11, 40(sp)
    sw x12, 44(sp)
    sw x13, 48(sp)
    sw x14, 52(sp)
    sw x15, 56(sp)
    sw x16, 60(sp)
    sw x17, 64(sp)
    sw x18, 68(sp)
    sw x19, 72(sp)
    sw x20, 76(sp)
    sw x21, 80(sp)
    sw x22, 84(sp)
    sw x23, 88(sp)
    sw x24, 92(sp)
    sw x25, 96(sp)
    sw x26, 100(sp)
    sw x27, 104(sp)
    sw x28, 108(sp)
    sw x29, 112(sp)
    sw x30, 116(sp)
    sw x31, 120(sp)

    /* find isr responsible to handling the interrupt*/
    csrrw t0, ustatus, x0
	slli t0, t0, 2		# multiply by 4 to account for ptr size
    la t1, extern_isr_lookup_table
    add t1, t1, t0
    lw t1, 0(t1)

    /* jump to the appropriate isr */
    jalr t1 
    
    /* restore correct context */
	LOAD	x1, 0x0(sp)
	LOAD	x4, 3 * REGBYTES(sp)
	LOAD	x5, 4 * REGBYTES(sp)
	LOAD	x6, 5 * REGBYTES(sp)
	LOAD	x7, 6 * REGBYTES(sp)
	LOAD	x8, 7 * REGBYTES(sp)
	LOAD	x9, 8 * REGBYTES(sp)
	LOAD	x10, 9 * REGBYTES(sp)
	LOAD	x11, 10 * REGBYTES(sp)
	LOAD	x12, 11 * REGBYTES(sp)
	LOAD	x13, 12 * REGBYTES(sp)
	LOAD	x14, 13 * REGBYTES(sp)
	LOAD	x15, 14 * REGBYTES(sp)
	LOAD	x16, 15 * REGBYTES(sp)
	LOAD	x17, 16 * REGBYTES(sp)
	LOAD	x18, 17 * REGBYTES(sp)
	LOAD	x19, 18 * REGBYTES(sp)
	LOAD	x20, 19 * REGBYTES(sp)
	LOAD	x21, 20 * REGBYTES(sp)
	LOAD	x22, 21 * REGBYTES(sp)
	LOAD	x23, 22 * REGBYTES(sp)
	LOAD	x24, 23 * REGBYTES(sp)
	LOAD	x25, 24 * REGBYTES(sp)
	LOAD	x26, 25 * REGBYTES(sp)
	LOAD	x27, 26 * REGBYTES(sp)
	LOAD	x28, 27 * REGBYTES(sp)
	LOAD	x29, 28 * REGBYTES(sp)
	LOAD	x30, 29 * REGBYTES(sp)
	LOAD	x31, 30 * REGBYTES(sp)

	addi	sp, sp, REGBYTES * 32
	uret


/* Startup code */
boot_strap:
	addi t0, x0, -1
    csrrw x0, 0x4, t0
    li	x1, 0
    li	x2, 0
    li	x3, 0
    li	x4, 0
    li	x5, 0
	li	x6, 0
    li	x7, 0
    li	x8, 0
    li	x9, 0
    li	x10, 0
    li	x11, 0
    li	x12, 0
    li	x13, 0
    li	x14, 0
    li	x15, 0
    li	x16, 0
    li	x17, 0
    li	x18, 0
    li	x19, 0
    li	x20, 0
    li	x21, 0
    li	x22, 0
    li	x23, 0
    li	x24, 0
    li	x25, 0
    li	x26, 0
    li	x27, 0
    li	x28, 0
    li	x29, 0
    li	x30, 0
    li	x31, 0

init_stack:
    /* set stack pointer */
    lui     sp, %hi(_fstack)
	addi    sp, sp, %lo(_fstack)
	j	main


/* Macro for saving task context */
.macro portSAVE_CONTEXT
	.global	pxCurrentTCB
	/* make room in stack */
	addi	sp, sp, -REGBYTES * 32

	/* Save Context */
	STORE	x1, 0x0(sp)
	STORE	x2, 1 * REGBYTES(sp)
	STORE	x3, 2 * REGBYTES(sp)
	STORE	x4, 3 * REGBYTES(sp)
	STORE	x5, 4 * REGBYTES(sp)
	STORE	x6, 5 * REGBYTES(sp)
	STORE	x7, 6 * REGBYTES(sp)
	STORE	x8, 7 * REGBYTES(sp)
	STORE	x9, 8 * REGBYTES(sp)
	STORE	x10, 9 * REGBYTES(sp)
	STORE	x11, 10 * REGBYTES(sp)
	STORE	x12, 11 * REGBYTES(sp)
	STORE	x13, 12 * REGBYTES(sp)
	STORE	x14, 13 * REGBYTES(sp)
	STORE	x15, 14 * REGBYTES(sp)
	STORE	x16, 15 * REGBYTES(sp)
	STORE	x17, 16 * REGBYTES(sp)
	STORE	x18, 17 * REGBYTES(sp)
	STORE	x19, 18 * REGBYTES(sp)
	STORE	x20, 19 * REGBYTES(sp)
	STORE	x21, 20 * REGBYTES(sp)
	STORE	x22, 21 * REGBYTES(sp)
	STORE	x23, 22 * REGBYTES(sp)
	STORE	x24, 23 * REGBYTES(sp)
	STORE	x25, 24 * REGBYTES(sp)
	STORE	x26, 25 * REGBYTES(sp)
	STORE	x27, 26 * REGBYTES(sp)
	STORE	x28, 27 * REGBYTES(sp)
	STORE	x29, 28 * REGBYTES(sp)
	STORE	x30, 29 * REGBYTES(sp)
	STORE	x31, 30 * REGBYTES(sp)
	
	/* Store current stackpointer in task control block (TCB) */
	LOAD	t0, pxCurrentTCB	//pointer
	STORE	sp, 0x0(t0)
	.endm

/* Saves current error program counter (EPC) as task program counter */
.macro portSAVE_EPC
  	csrrw	t0, EPC, zero // we override it and restore it since
	csrrw	zero, EPC, t0 // dwarf32 doesn't support 
							//other control instructions such as csrrc or csrrs
	STORE	t0, 31 * REGBYTES(sp)
	.endm

/* Saves current return adress (RA) as task program counter */
.macro portSAVE_RA
	STORE	ra, 31 * REGBYTES(sp)
	.endm

/* Macro for restoring task context */
.macro portRESTORE_CONTEXT

	.global	pxCurrentTCB
	/* Load stack pointer from the current TCB */
	LOAD	sp, pxCurrentTCB
	LOAD	sp, 0x0(sp)

	/* Load task program counter */
	LOAD	t0, 31 * REGBYTES(sp)
  	csrrw	zero ,EPC, t0 // load new epc

	/* Restore registers,
	   Skip global pointer because that does not change */
	LOAD	x1, 0x0(sp)
	LOAD	x4, 3 * REGBYTES(sp)
	LOAD	x5, 4 * REGBYTES(sp)
	LOAD	x6, 5 * REGBYTES(sp)
	LOAD	x7, 6 * REGBYTES(sp)
	LOAD	x8, 7 * REGBYTES(sp)
	LOAD	x9, 8 * REGBYTES(sp)
	LOAD	x10, 9 * REGBYTES(sp)
	LOAD	x11, 10 * REGBYTES(sp)
	LOAD	x12, 11 * REGBYTES(sp)
	LOAD	x13, 12 * REGBYTES(sp)
	LOAD	x14, 13 * REGBYTES(sp)
	LOAD	x15, 14 * REGBYTES(sp)
	LOAD	x16, 15 * REGBYTES(sp)
	LOAD	x17, 16 * REGBYTES(sp)
	LOAD	x18, 17 * REGBYTES(sp)
	LOAD	x19, 18 * REGBYTES(sp)
	LOAD	x20, 19 * REGBYTES(sp)
	LOAD	x21, 20 * REGBYTES(sp)
	LOAD	x22, 21 * REGBYTES(sp)
	LOAD	x23, 22 * REGBYTES(sp)
	LOAD	x24, 23 * REGBYTES(sp)
	LOAD	x25, 24 * REGBYTES(sp)
	LOAD	x26, 25 * REGBYTES(sp)
	LOAD	x27, 26 * REGBYTES(sp)
	LOAD	x28, 27 * REGBYTES(sp)
	LOAD	x29, 28 * REGBYTES(sp)
	LOAD	x30, 29 * REGBYTES(sp)
	LOAD	x31, 30 * REGBYTES(sp)

	addi	sp, sp, REGBYTES * 32
	uret
	.endm


TIMER_INT_HANDLER:
	portSAVE_CONTEXT
	portSAVE_EPC
	jal	vPortSysTickHandler
	portRESTORE_CONTEXT

xPortStartScheduler:
#ifdef __gracefulExit
	/* Stores context when starting the scheduler in xStartContext.
	   This is used for when you want to gracefully exit the scheduler.
	   For example if you want to test multiple instances after each other in one test suite.
     */
	la		t0, xStartContext
	STORE	x1, 0x0(t0)
	STORE	x2, 1 * REGBYTES(t0)
	STORE	x3, 2 * REGBYTES(t0)
	STORE	x4, 3 * REGBYTES(t0)
	STORE	x5, 4 * REGBYTES(t0)
	STORE	x6, 5 * REGBYTES(t0)
	STORE	x7, 6 * REGBYTES(t0)
	STORE	x8, 7 * REGBYTES(t0)
	STORE	x9, 8 * REGBYTES(t0)
	STORE	x10, 9 * REGBYTES(t0)
	STORE	x11, 10 * REGBYTES(t0)
	STORE	x12, 11 * REGBYTES(t0)
	STORE	x13, 12 * REGBYTES(t0)
	STORE	x14, 13 * REGBYTES(t0)
	STORE	x15, 14 * REGBYTES(t0)
	STORE	x16, 15 * REGBYTES(t0)
	STORE	x17, 16 * REGBYTES(t0)
	STORE	x18, 17 * REGBYTES(t0)
	STORE	x19, 18 * REGBYTES(t0)
	STORE	x20, 19 * REGBYTES(t0)
	STORE	x21, 20 * REGBYTES(t0)
	STORE	x22, 21 * REGBYTES(t0)
	STORE	x23, 22 * REGBYTES(t0)
	STORE	x24, 23 * REGBYTES(t0)
	STORE	x25, 24 * REGBYTES(t0)
	STORE	x26, 25 * REGBYTES(t0)
	STORE	x27, 26 * REGBYTES(t0)
	STORE	x28, 27 * REGBYTES(t0)
	STORE	x29, 28 * REGBYTES(t0)
	STORE	x30, 29 * REGBYTES(t0)
	STORE	x31, 30 * REGBYTES(t0)
#endif
	
	jal		vPortSetupTimer
	portRESTORE_CONTEXT

vPortEndScheduler:
#ifdef __gracefulExit
	/* Load current context from xStartContext */
	la		t0, xStartContext
	LOAD	x1, 0x0(t0)
	LOAD	x2, 1 * REGBYTES(t0)
	LOAD	x3, 2 * REGBYTES(t0)
	LOAD	x4, 3 * REGBYTES(t0)
	LOAD	x5, 4 * REGBYTES(t0)
	LOAD	x6, 5 * REGBYTES(t0)
	LOAD	x7, 6 * REGBYTES(t0)
	LOAD	x8, 7 * REGBYTES(t0)
	LOAD	x9, 8 * REGBYTES(t0)
	LOAD	x10, 9 * REGBYTES(t0)
	LOAD	x11, 10 * REGBYTES(t0)
	LOAD	x12, 11 * REGBYTES(t0)
	LOAD	x13, 12 * REGBYTES(t0)
	LOAD	x14, 13 * REGBYTES(t0)
	LOAD	x15, 14 * REGBYTES(t0)
	LOAD	x16, 15 * REGBYTES(t0)
	LOAD	x17, 16 * REGBYTES(t0)
	LOAD	x18, 17 * REGBYTES(t0)
	LOAD	x19, 18 * REGBYTES(t0)
	LOAD	x20, 19 * REGBYTES(t0)
	LOAD	x21, 20 * REGBYTES(t0)
	LOAD	x22, 21 * REGBYTES(t0)
	LOAD	x23, 22 * REGBYTES(t0)
	LOAD	x24, 23 * REGBYTES(t0)
	LOAD	x25, 24 * REGBYTES(t0)
	LOAD	x26, 25 * REGBYTES(t0)
	LOAD	x27, 26 * REGBYTES(t0)
	LOAD	x28, 27 * REGBYTES(t0)
	LOAD	x29, 28 * REGBYTES(t0)
	LOAD	x30, 39 * REGBYTES(t0)
	LOAD	x31, 30 * REGBYTES(t0)
#endif
	ret

vPortYield:
	/*
	*  This routine can be called from outside of interrupt handler. This means
	*  interrupts may be enabled at this point. This is probably okay for registers and
	*  stack. However, "mepc" will be overwritten by the interrupt handler if a timer
	*  interrupt happens during the yield. To avoid this, prevent interrupts before starting.
	*  The write to mstatus in the restore context routine will enable interrupts after the
	*  mret. A more fine-grain lock may be possible.
	*/  
	csrrci x0, UIE, 0x1

	portSAVE_CONTEXT
	portSAVE_RA
	jal	vTaskSwitchContext
	portRESTORE_CONTEXT

/* For when a trap is fired */
external_interrupt_handler:
	/* System call and other traps */
	addi sp, sp, -REGBYTES*31
	STORE x1, 1*REGBYTES(sp)
	STORE x2, 2*REGBYTES(sp)
	STORE x3, 3*REGBYTES(sp)
	STORE x4, 4*REGBYTES(sp)
	STORE x5, 5*REGBYTES(sp)
	STORE x6, 6*REGBYTES(sp)
	STORE x7, 7*REGBYTES(sp)
	STORE x8, 8*REGBYTES(sp)
	STORE x9, 9*REGBYTES(sp)
	STORE x10, 10*REGBYTES(sp)
	STORE x11, 11*REGBYTES(sp)
	STORE x12, 12*REGBYTES(sp)
	STORE x13, 13*REGBYTES(sp)
	STORE x14, 14*REGBYTES(sp)
	STORE x15, 15*REGBYTES(sp)
	STORE x16, 16*REGBYTES(sp)
	STORE x17, 17*REGBYTES(sp)
	STORE x18, 18*REGBYTES(sp)
	STORE x19, 19*REGBYTES(sp)
	STORE x20, 20*REGBYTES(sp)
	STORE x21, 21*REGBYTES(sp)
	STORE x22, 22*REGBYTES(sp)
	STORE x23, 23*REGBYTES(sp)
	STORE x24, 24*REGBYTES(sp)
	STORE x25, 25*REGBYTES(sp)
	STORE x26, 26*REGBYTES(sp)
	STORE x27, 27*REGBYTES(sp)
	STORE x28, 28*REGBYTES(sp)
	STORE x29, 29*REGBYTES(sp)
	STORE x30, 30*REGBYTES(sp)
	STORE x31, 31*REGBYTES(sp)

	/* caller appropriate handler */

	/* time to resume normal execution */
	LOAD x1, 1*REGBYTES(sp)
	LOAD x2, 2*REGBYTES(sp)
	LOAD x3, 3*REGBYTES(sp)
	LOAD x4, 4*REGBYTES(sp)
	LOAD x5, 5*REGBYTES(sp)
	LOAD x6, 6*REGBYTES(sp)
	LOAD x7, 7*REGBYTES(sp)
	LOAD x8, 8*REGBYTES(sp)
	LOAD x9, 9*REGBYTES(sp)
	LOAD x10, 10*REGBYTES(sp)
	LOAD x11, 11*REGBYTES(sp)
	LOAD x12, 12*REGBYTES(sp)
	LOAD x13, 13*REGBYTES(sp)
	LOAD x14, 14*REGBYTES(sp)
	LOAD x15, 15*REGBYTES(sp)
	LOAD x16, 16*REGBYTES(sp)
	LOAD x17, 17*REGBYTES(sp)
	LOAD x18, 18*REGBYTES(sp)
	LOAD x19, 19*REGBYTES(sp)
	LOAD x20, 20*REGBYTES(sp)
	LOAD x21, 21*REGBYTES(sp)
	LOAD x22, 22*REGBYTES(sp)
	LOAD x23, 23*REGBYTES(sp)
	LOAD x24, 24*REGBYTES(sp)
	LOAD x25, 25*REGBYTES(sp)
	LOAD x26, 26*REGBYTES(sp)
	LOAD x27, 27*REGBYTES(sp)
	LOAD x28, 28*REGBYTES(sp)
	LOAD x29, 29*REGBYTES(sp)
	LOAD x30, 30*REGBYTES(sp)
	LOAD x31, 31*REGBYTES(sp)

	addi sp, sp, REGBYTES*31
	uret
