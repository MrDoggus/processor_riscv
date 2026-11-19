`ifndef RISCV_PKG_SVH
`define RISCV_PKG_SVH

package riscv_pkg;

parameter INSTR_W = 32;
parameter INSTR_BYTEW = INSTR_W / 8;

parameter OP_W = 7;
parameter FUNCT3_W = 3;
parameter RUNCT7_W = 7;
paramter REG_W = 5;

typedef logic [FUNCT3_W-1:0] funct3_t;
typedef logic [FUNCT7_W-1:0] funct7_t;
typedef logic [REG_W-1:0] reg_t;

// opcodes
typedef enum logic [OP_W-1:0] {
    OP_LOAD     = 7'b000_0011,  // (I) LB, LH, LW, LBU, LHU
    OP_ORDER    = 7'b000_1111,  // FENCE, PAUSE
    OP_ALUI     = 7'b001_0011,  // (I) ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    OP_AUIPC    = 7'b001_0111,  // (U) Load upper immediate + program counter
    OP_ALUIW    = 7'b001_1011,  // (I) ADDIW, SLLIW, SRLIW, SRAIW (RV64I)
    OP_STORE    = 7'b010_0011,  // (S) SB, SH, SW
    OP_ALU      = 7'b011_0011,  // (R) ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    OP_LUI      = 7'b011_0111,  // (U) Load upper immediate
    OP_ALUIW    = 7'b011_1011,  // (R) ADDW, SUBW, SLLW, SRLW, SRAW
    OP_BRANCH   = 7'b110_0011,  // (B) BEQ, BNE, BLT, BGE, BLTU, BGEU
    OP_JALR     = 7'b110_0111,  // (I) Jump and link register
    OP_JAL      = 7'b110_1111,  // (J) Jump and link
    OP_SYS      = 7'b111_0011   // (I?) ECALL, EBREAK, CSR[Zicsr]
} opcode_t;

// Load funct3
typedef enum funct3_t {
    FUNCT3_LB   = 3'b000,   // Load byte
    FUNCT3_LH   = 3'b001,   // Load half-word
    FUNCT3_LW   = 3'b010,   // Load word
    FUNCT3_LD   = 3'b011,   // Load double-word (RV64I)
    FUNCT3_LBU  = 3'b100,   // Load byte unsigned
    FUNCT3_LHU  = 3'b101,   // Load half-word unsigned
    FUNCT3_LWU  = 3'b110    // Load word unsigned (RV64I)
} load_funct3_t;

// ALU-immediate funct3
// NOTE: For RV64I, SLLI, SRLI, SRAI have a shamt that is larger by 1 bit.  
typedef enum funct3_t {
    FUNCT3_ADDI     = 3'b000,   // Add immediate
    FUNCT3_SLTI     = 3'b010,   // Set less than immediate
    FUNCT3_SLTIU    = 3'b011,   // Set less than immediate unsigned
    FUNCT3_XORI     = 3'b100,   // XOR immediate
    FUNCT3_ORI      = 3'b110,   // OR immediate
    FUNCT3_ANDI     = 3'b111,   // AND immediate
    FUNCT3_SLLI     = 3'b001,   // Shift left logical immediate 
    FUNCT3_SRXI     = 3'b101    // SRLI, SRAI
} alui_funct3_t;

// SRLI / SRAI funct7
typedef enum funct7_t {
    FUNCT7_SRLI = 7'b000_0000,  // Shift right logical immediate
    FUNCT7_SRAI = 7'b010_0000   // Shift right arithmetic immediate
} srxi_funct3_t;

// ALU immediate word funct3 (RV64I) 
typedef enum funct3_t {
    FUNCT3_ADDIW     = 3'b000,  // Add immediate word
    FUNCT3_SLLIW     = 3'b001,  // Shift left logical immediate word
    FUNCT3_SRXIW     = 3'b101   // SRLIW, SRAIW
} aluiw_funct3_t;

// Shift right immediate word funct7 (RV64I)
typedef enum funct7_t {
    FUNCT7_SRLIW    = 7'b000_0000,  // Shift right logical immediate word
    FUNCT7_SRAIW    = 7'b010_0000   // Shift right arithmetic immediate word
} srxiw_funct7_t;

// Store funct3
typedef enum funct3_t {
    FUNCT3_SB   = 3'b000,   // Store byte
    FUNCT3_SH   = 3'b001,   // Store half-word
    FUNCT3_SW   = 3'b010,   // Store word
    FUNCT3_SD   = 3'b011    // Store double-word (RV64I)
} store_funct3_t;

// ALU funct3
typedef enum funct3_t {
    FUNCT3_SLL    = 3'b001, // Shift logical left
    FUNCT3_ADDSUB = 3'b000, // ADD, SUB
    FUNCT3_SLT    = 3'b010, // Set less than
    FUNCT3_SLTU   = 3'b011, // Set less than unsigned
    FUNCT3_XOR    = 3'b100, // XOR
    FUNCT3_SRX    = 3'b101, // SRL, SRA
    FUNCT3_OR     = 3'b110, // OR
    FUNCT3_AND    = 3'b111  // AND
} alu_funct3_t;

// ADD / SUB funct7
typedef enum funct7_t {
    FUNCT7_ADD  = 7'b000_0000,  // Add
    FUNCT7_SUB  = 7'b010_0000   // Subtract
} addsub_funct7_t;

// SRL / SRA funct7
typedef enum funct7_t {
    FUNCT7_SRL  = 7'b000_0000,  // Shift right logical
    FUNCT7_SRA  = 7'b010_0000   // Shift right arithmetic
} addsub_funct7_t;

// ALU word funct3 (RV64I)
typedef enum funct3_t {
    FUNCT3_ADDSUBW  = 3'b000,
    FUNCT3_SLLIW    = 3'b001,
    FUNCT3_SRXW     = 3'b101
} aluw_funct3_t;

// ADD / SUB word funct7 (RV64I)
typedef enum funct7_t {
    FUNCT7_ADDW = 7'b000_0000,
    FUNCT7_SUBW = 7'b010_0000
} addsubw_funct7_t;

// Shift right word funct7 (RV64I)
typedef enum funct7_t {
    FUNCT7_SRLW = 7'b000_0000,
    FUNCT7_SRAW = 7'b010_0000
} addsubw_funct7_t;

// Branch funct3
typedef enum funct3_t {
    BFUNCT_BEQ  = 3'b000,   // Equal
    BFUNCT_BNE  = 3'b001,   // Not equal
    BFUNCT_BLT  = 3'b100,   // Less than signed
    BFUNCT_BGE  = 3'b101,   // Greater than or equal signed
    BFUNCT_BLTU = 3'b110,   // Less than unsigned
    BFUNCT_BGEU = 3'b111    // Greater than or equal unsigned
} branch_funct3_t;


// Non-standard...
// FENCE
// FENCE.TSO
// FENCE.I (Zifencei)
// PAUSE
// ECALL
// EBREAK
// CSR (Zicsr)

// General instruction
typedef struct packed {
    logic [26:0] data;
    opcode_t opcode;
} ginstr_t;

// R-type
typedef struct packed {
    funct7_t funct7;
    reg_t rs2;
    reg_t rs1;
    funct3_t funct3;
    reg_t rd;
    opcode_t opcode;
} rtype_t;

// I-type
typedef struct packed {
    logic [11:0] imm;
    reg_t rs1;
    funct3_t funct3;
    reg_t rd;
    opcode_t opcode;
} itype_t;

// S-type
typedef struct packed {
    logic [6:0] imm_11_5;
    reg_t rs2;
    reg_t rs1;
    funct3_t funct3;
    logic [4:0] imm_4_0;
    opcode_t opcode;
} stype_t;

// B-type
typedef struct packed {
    logic imm_12;
    logic [5:0] imm_10_5;
    reg_t rs2;
    reg_t rs1;
    funct3_t funct3;
    logic [3:0] imm_4_1;
    logic imm_11;
    opcode_t opcode;
} btype_t;

// U-type
typedef struct packed {
    logic [19:0] imm;
    reg_t rd;
    opcode_t opcode;
} utype_t;

// J-type
typedef struct packed {
    logic imm_20;
    logic [9:0] imm_10_1;
    logic imm_11;
    logic [7:0] imm_19_12;
    reg_t rd;
    opcode_t opcode;
} jtype_t;



// Instruction type
typedef union packed {
    logic [INSTR_W-1:0] raw_instr;
    ginstr_t gen_instr;
    rtype_t r;
    itype_t i;
    stype_t s;
    btype_t b;
    utype_t u;
    jtype_t j;
} instr_t;

localparam itype_t NOP_I = '{
    imm: 12'b0000_0000_0000,
    rs1: 5'b00000,
    funct3: FUNCT3_ADDI,
    rd: 5'b00000,
    opcode: OP_ALUI
};

parameter instr_t INSTR_NOP = instr_t'(NOP_I);

endpackage

`endif