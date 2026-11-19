`ifndef TRAP_PKG_SVH
`define TRAP_PKG_SVH

package trap_pkg;

parameter int unsigned SXLEN = 32;
parameter int unsigned TRAP_CAUSE_W = $clog2(19 + 1); // Largest trap cause is 19

typedef enum logic [TRAP_CAUSE_W-1:0] {
    TRAP_INT_SSW = 1, // Supervisor software interrupt
    TRAP_INT_MSW = 3, // Machine software interrupt
    TRAP_INT_STIMER = 5, // Supervisor timer interrupt
    TRAP_INT_MTIMER = 7, // Machine timer interrupt
    TRAP_INT_SEXT = 9, // Supervisor external interrupt
    TRAP_INT_MEXT = 11, // Machine external interrupt
    TRAP_INT_CNT_OVERFLOW = 13 // Counter overflow interrupt
} trap_interrupt_code_t;

typedef enum logic [TRAP_CAUSE_W-1:0] {
    TRAP_EXC_INSTR_MISALIGN = 0, // Instruction address misaligned
    TRAP_EXC_INSTR_ACCESS = 1, // Instruction access fault
    TRAP_EXC_ILLEGAL_INSTR = 2, // Illegal instruction
    TRAP_EXC_BREAKPOINT = 3, // Breakpoint
    TRAP_EXC_LOAD_MISALIGN = 4, // Load address misaligned
    TRAP_EXC_LOAD_ACCESS = 5, // Load access fault
    TRAP_EXC_STORE_MISALIGN = 6, // Store/AMO address misaligned
    TRAP_EXC_STORE_ACCESS = 7, // Store/AMO access fault
    TRAP_EXC_ENV_CALL_UM = 8, // Environment call from user mode
    TRAP_EXC_ENV_CALL_S = 9, // Environment call from supervisor mode
    TRAP_EXC_ENV_CALL_M = 11, // Environment call from machine mode
    TRAP_EXC_INSTR_PAGE_FAULT = 12, // Instruction page fault
    TRAP_EXC_LOAD_PAGE_FAULT = 13, // Load page fault
    TRAP_EXC_STORE_PAGE_FAULT = 15, // Store/AMO page fault
    TRAP_EXC_DOUBLE_TRAP = 16, // Double trap
    TRAP_EXC_SW_CHECK = 18, // Software check
    TRAP_EXC_HW_ERROR = 19 // Hardware error
} trap_exception_code_t;

typedef union packed {
    logic [TRAP_CAUSE_W-1:0] raw_code;
    trap_interrupt_code_t interrupt_code;
    trap_exception_code_t exception_code;
} trap_code_t;

typedef struct packed {
    logic isInterrupt;
    logic [SXLEN - TRAP_CAUSE_W - 2:0] _buf;
    trap_code_t code;
} trap_cause_reg_t;

endpackage
`endif