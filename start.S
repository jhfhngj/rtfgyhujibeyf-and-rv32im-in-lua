.section .text.start
.global _start
.extern freertos_risc_v_trap_handler
.extern main

_start:
    li sp, 0x7FF0
    la t0, freertos_risc_v_trap_handler
    csrw mtvec, t0
    jal main
    ebreak
