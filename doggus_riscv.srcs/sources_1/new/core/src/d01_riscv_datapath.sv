// Module description: 
// RISCV d01 Datapath
// 
// Parameters: 
// XLEN:        Data width of the core.
// 
// Ports:
// clk:         System clock input.
// rst_n:       Active low reset input.
// wb_imem_if:  Wishbone instruction memory interface.
// wb_dmem_if:  Wishbone data memory interface.
// 
// Dependencies:
// - None
// 
// Version: 01.00

`include "wishbone_if.svh"

module d01_riscv_datapath #(
    parameter int unsigned XLEN = 64
    parameter logic [63:0] RESET_PC = 64'h00
) (
    input logic clk, rst_n,

    // Wishbone interface
    wishbone_if.master wb_imem_if,
    wishbone_if.master wb_dmem_if
);
    
    // --- Signals --- //
    logic [XLEN-1:0] if_next_pc; // Next program counter.
    logic if_req; // Next instruction request valid.
    logic if_cancel; // Next instruction request cancel.
    logic [31:0] if_instr; // Fetched instruction.
    logic if_ready; // Fetched instruction is ready.
    logic if_stall; // Stall signal caused by later pipe stages. 
    logic if_pipe_latch; // Latch IF state for next pipe stage.
    logic if_pipe_nop; // Latch NOP operation for next pipe stage.

    logic recov_pc_wen; // Recovery counter write enable.
    logic [XLEN-1:0] recov_pc; // Program counter.

    logic if_latch_nop; // Instruction fetch latch is NOP. 
    logic [31:0] if_latch_instr; // Instruction fetch latch is instruction.
    logic [XLEN-1:0] if_latch_pc; // Instruction fetch latch is PC.


    // --- Instruction Fetch --- //

    d01_instruction_fetch #(
        .XLEN(XLEN)
    ) if_unit (
        .clk(clk),
        .rst_n(rst_n),
        .wb_imem_if(wb_imem_if),
        .pc_i(if_pc),
        .req_i(if_req),
        .cancel_i(if_cancel),
        .instr_o(if_instr),
        .ready_o(if_ready)
    );
    assign if_req = !if_stall && !if_cancel;


    // --- Program Counter --- //
    
    // Cancel transaction if we are waiting on a read and the PC needs to be corrected.
    assign if_cancel = recov_pc_wen && !if_ready;
    always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n == 1'b0) begin
            if_pc <= (XLEN)'(RESET_PC);
        end
        else if (recov_pc_wen) begin
            if_pc <= recov_pc;
        end
        else if (if_pipe_latch) begin
            if_pc <= if_pc + 4;
        end
    end


    // --- Instruction Fetch Latch --- //

    // Do not change latch state if the next stage needs to stall. 
    // Latch IF state if the next instruction is ready and we are not recovering from a branch misprediction / exception.
    // Insert a bubble if the next instruction is not ready or if we are recovering from a branch misprediction / exception.
    assign if_pipe_latch = if_ready && !recov_pc_wen && !if_stall;
    assign if_pipe_nop = (!if_ready || recov_pc_wen) && !if_stall;

    latch #(
        .WIDTH(1)
    ) if_latch_pc (
        .clk(clk),
        .rst_n(rst_n),
        .wen(if_pipe_latch)
        .latch_i(if_pipe_nop),
        .latch_o(if_latch_valid),
    );

    latch #(
        .WIDTH(32)
    ) if_latch_instr (
        .clk(clk),
        .rst_n(rst_n),
        .wen(if_pipe_latch)
        .latch_i(if_instr),
        .latch_o(if_latch_instr),
    );

    latch #(
        .WIDTH(XLEN)
    ) if_latch_pc (
        .clk(clk),
        .rst_n(rst_n),
        .wen(if_pipe_latch)
        .latch_i(if_pc),
        .latch_o(if_latch_pc),
    );


    // --- Instruction Decode --- //

endmodule 