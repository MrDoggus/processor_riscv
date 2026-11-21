`ifndef DATAPATH_PKG_SVH
`define DATAPATH_PKG_SVH

package datapath_pkg;

import riscv_pkg::*;


// --- Traps and Errors --- //

// Traps generated from instruction fetch.
parameter int unsigned IF_TRAP_CAUSE_W = 2;
typedef enum logic [IF_TRAP_CAUSE_W-1:0] {
    IF_TRAP_CAUSE_NONE = 0,
    IF_TRAP_CAUSE_INSTR_MISALIGN = 1,
    IF_TRAP_CAUSE_WISHBONE = 2
} if_trap_cause_t;

// Traps asserted from instruction decode.
parameter int unsigned DEC_TRAP_CAUSE_W = 3;
typedef enum logic [DEC_TRAP_CAUSE_W-1:0] {
    DEC_TRAP_CAUSE_NONE = 0,
    DEC_TRAP_CAUSE_INSTR_MISALIGN = 1,
    DEC_TRAP_CAUSE_WISHBONE = 2,
    DEC_TRAP_CAUSE_ILLEGAL_INSTR = 3,
    DEC_TRAP_CAUSE_EBREAK = 4,
    DEC_TRAP_CAUSE_ECALL = 5
} dec_trap_cause_t;


// --- Issue Queue --- //

// Width of instruction index used in ROB. 
// Extra bit is used to help determine relative age of instructions. 
parameter int unsigned INSTR_IDX_W = 4 + 1;
typedef logic [INSTR_IDX_W-1:0] instr_idx_t;

// Pipeline class
parameter int unsigned PIPE_CLASS_W = 1;
typedef enum logic [PIPE_CLASS_W-1:0] {
    PIPE_CLASS_INT = 1'b0,
    PIPE_CLASS_MEM = 1'b1
} pipe_class_t;

// Op code for integer pipeline
parameter int unsigned INT_OP_W = 5
typedef enum logic [INT_OP_W-1:0] {
    INT_OP_JAL = 5'b00000,
    INT_OP_JALR = 5'b00001,
    INT_OP_BEQ = 5'b00010,
    INT_OP_BNE = 5'b00011,

    INT_OP_BLT = 5'b00100,
    INT_OP_BGE = 5'b00101,
    INT_OP_BLTU = 5'b00110,
    INT_OP_BGEU = 5'b00111,

    INT_OP_ADDI = 5'b01000, 
    INT_OP_ADD = 5'b01001,
    INT_OP_SUB = 5'b01011,

    INT_OP_SLTI = 5'b01100,
    INT_OP_SLT = 5'b01101,
    INT_OP_SLTIU = 5'b0110,
    INT_OP_SLTU = 5'b01111,
    
    INT_OP_ORI = 5'b10000,
    INT_OP_OR = 5'b10001,
    INT_OP_ANDI = 5'b10010,
    INT_OP_AND = 5'b10011,
    INT_OP_XORI = 5'b10100,
    INT_OP_XOR = 5'b10101,

    INT_OP_LUI = 5'b11000,
    INT_OP_AUIPC = 5'b11001,
    INT_OP_SLLI = 5'b11010,
    INT_OP_SLL = 5'b11011,
    INT_OP_SRLI = 5'b11100,
    INT_OP_SRL = 5'b11101,
    INT_OP_SRAI = 5'b11110,
    INT_OP_SRA = 5'b11111,
} int_op_t;

// Op code for memory pipeline
parameter int unsigned MEM_OP_W = 4;
typedef enum logic [MEM_OP_W-1:0] {
    MEM_OP_NOP = 4'b0000,
    MEM_OP_SB = 4'b0001,
    MEM_OP_SH = 4'b0011,
    MEM_OP_SW = 4'b0101,
    MEM_OP_SD = 4'b0111,

    MEM_OP_LBU = 4'b1000,
    MEM_OP_LB = 4'b1001,
    MEM_OP_LHU = 4'b1010,
    MEM_OP_LH = 4'b1011,
    MEM_OP_LWU = 4'b1100,
    MEM_OP_LW = 4'b1101,
    MEM_OP_LD = 4'b1111
    
} mem_op_t;

parameter INT_CTRL_W = INT_OP_W + ADDR_W;
parameter MEM_CTRL_W = MEM_OP_W + INSTR_IDX_W + INSTR_IDX_W;

parameter logic ALU_CTRL_LARGEST = INT_OP_W > MEM_OP_W;
parameter logic MEM_CTRL_LARGEST = MEM_OP_W > INT_OP_W;
parameter logic IQ_FRAME_W = ALU_CTRL_LARGEST ? INT_CTRL_W : MEM_CTRL_W;

// Integer instruction meta for issue queue frame.
typedef struct packed {
    logic [IQ_FRAME_W - INT_CTRL_W - 1:0] _pad;
    addr_t pc;
    int_op_t int_op;
} int_ctrl_t;

// Memory instruction meta for issue queue frame.
typedef struct packed {
    logic [IQ_FRAME_W - MEM_CTRL_W - 1:0] _pad;
    instr_idx_t sfence_idx; // Index of store instruction that needs to be flushed to memory before executing this instr.
    instr_idx_t lfence_idx; // Index of load instruction that needs to be retired before executing this instr.
    mem_op_t mem_op;
} mem_ctrl_t;

// Instruction meta for issue queue frame.
typedef union packed {
    logic [IQ_FRAME_W - 1:0] raw;
    int_ctrl_t int_ctrl;
    mem_ctrl_t mem_ctrl;
} iq_meta_t;

// Issue queue frame.
typedef struct packed {
    iq_meta_t meta;
    logic [20:0] imm;
    reg_t rs2;
    reg_t rs1;
    reg_t rd;
    instr_idx_t idx;
    pipe_class_t pipe_class;
} iq_frame_t;

endpackage

`endif