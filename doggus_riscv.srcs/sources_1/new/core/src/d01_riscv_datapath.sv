// Module description: 
// RISCV d01 Datapath
// 
// Parameters: 
// _
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
`include "riscv_pkg.svh"

module d01_riscv_datapath 
    import riscv_pkg::*;
    import trap_pkg::*;
    import datapath_pkg::*;
#(
    parameter logic RV64I = 1'b1,
    parameter logic C_EXTENSION = 1'b0,
    parameter logic [63:0] RESET_PC = 64'h00
) (
    input logic clk, rst_n,

    // Wishbone interface
    wishbone_if.master wb_imem_if,
    wishbone_if.master wb_dmem_if
);

if (C_EXTENSION == 1'b1) begin
    $fatal("Compressed extension is not supported yet");
end

    // --- Local parameters --- //
    
    localparam int unsigned IALIGN = C_EXTENSION ? 16 : 32;
    

    // --- Signals --- //

    addr_t if_next_pc; // Next program counter.
    logic if_req; // Next instruction request valid.
    logic if_cancel; // Next instruction request cancel.
    logic if_flush; // Flush current instruction fetch state.
    instr_t if_instr; // Fetched instruction.
    logic if_ready; // Fetched instruction is ready.
    logic if_error; // Error during instruction fetch.
    if_trap_cause_t if_trap_cause; // Trap cause during instruction fetch.
    logic if_stall; // Stall signal caused by later pipe stages. 
    logic if_pipe_latch; // Latch IF state for next pipe stage.
    logic if_pipe_nop; // Latch NOP operation for next pipe stage.

    logic restore_pc_wen; // Restore counter write enable.
    addr_t restore_pc; // Program counter.

    logic if_latch_nop; // Instruction fetch latch is NOP. 
    if_trap_cause_t if_latch_trap_cause; // Trap cause during instruction fetch.
    instr_t if_latch_instr; // Instruction fetch latch is instruction.
    addr_t if_latch_pc; // Instruction fetch latch is PC.


    // --- Instruction Fetch --- //

    d01_instruction_fetch #(
        .C_EXTENSION(C_EXTENSION)
    ) if_unit (
        .clk(clk),
        .rst_n(rst_n),
        .wb_imem_if(wb_imem_if),
        .pc_i(if_pc),
        .req_i(if_req),
        .cancel_i(if_flush),
        .instr_o(if_instr),
        .ready_o(if_ready),
        .error_o(if_error)
    );
    assign if_req = !if_stall && !if_flush;


    // --- Program Counter --- //
    
    // Cancel transaction if we are waiting on a read and the PC needs to be corrected.
    assign if_flush = restore_pc_wen;
    always_ff @(posedge clk, negedge rst_n) begin
        if (rst_n == 1'b0) begin
            if_pc <= (ADDR_W)'(RESET_PC);
        end
        else if (restore_pc_wen) begin
            if_pc <= restore_pc;
        end
        else if (if_pipe_latch) begin
            if_pc <= if_pc + 4;
        end
    end


    // --- Instruction Fetch Latch --- //

    // Do not change latch state if the next stage needs to stall. 
    // Latch IF state if the next instruction is ready and we are not restoring from a branch misprediction / exception.
    // Insert a bubble if the next instruction is not ready or if we are restoring from a branch misprediction / exception.
    assign if_error = if_trap_cause != IF_TRAP_CAUSE_NONE;
    assign if_pipe_latch = if_ready && !if_flush && !if_stall;
    assign if_pipe_nop = (!if_ready || if_flush) && !if_stall && !if_error;

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
        .WIDTH(IF_TRAP_CAUSE_W)
    ) if_latch_trap_cause (
        .clk(clk),
        .rst_n(rst_n),
        .wen(if_pipe_latch)
        .latch_i(if_trap_cause),
        .latch_o(if_latch_trap_cause),
    );

    // NOTE: if_latch_valid should cause instruction to be treated as NOP. Dont want to set the 
    //   latch input to NOP to reduce the timing from cache/memory to the pipe. 
    latch #(
        .WIDTH(INSTR_W)
    ) if_latch_instr (
        .clk(clk),
        .rst_n(rst_n),
        .wen(if_pipe_latch)
        .latch_i(if_instr),
        .latch_o(if_latch_instr),
    );

    latch #(
        .WIDTH(ADDR_W)
    ) if_latch_pc (
        .clk(clk),
        .rst_n(rst_n),
        .wen(if_pipe_latch)
        .latch_i(if_pc),
        .latch_o(if_latch_pc),
    );


    // --- Instruction Decode --- //

    // NOTES:
    // PAUSE will wait for instructions before it to retire
    // FENCE
    //   - I and R treated as the same in my datapath (r = I or R)
    //   - O and W treated as the same in my datapath (w = O or W)
    //   - Keep track of the instr index of the latest queued store (s_q) and latest queued load (l_q) instructions
    //   - When a fence instruction is queued, move the store and load indexes into one or many registers
    //     - r,r: New read instructions must wait for loads prior to this stored index to retire. 
    //     - r,w: New write instructions must wait for loads prior to this stored index to retire. 
    //     - w,r: New read instructions must wait for stores prior to this stored index to be performed (retired and 
    //         written to memory). 
    //     - w,w: New write instructions must wait for stores prior to this stored index to be performed (retired and 
    //         written to memory). 
    //   - fence r,r: r,r = l_q
    //   - fence r,w: r,w = l_q
    //   - fence w,r: w,r = s_q
    //   - fence w,w: w,w = s_q
    //   - fence r,rw: r,r = l_q; r,w = l_q
    //   - fence w,rw: w,r = s_q; w,w = s_q
    //   - fence rw,r: r,r = l_q; w,r = s_q
    //   - fence rw,w: r,w = l_q; w,w = s_q
    //   - For loads, r,r and r,w indexes are passed to the queue for the MEM stage to handle. 
    //   - For stores, w,r and w,w indexes are passed to the queue for the MEM stage to handle. 
    //   - If no fence instruction or all fence instructions are completed, set x,r and x,w to the latest retired index. 
    //   - This should allow these loads/stores to retire/flush in any order when there is no fence instruction in scope. 
    // FENCE.TSO
    //   - Equivalent to fence r,rw; fence w,w
    //   - r,r = l_q, r,w = l_q, w,w = s_q
    // FENCE restoring
    //   - When a restore happens, set the l_q and s_q values to the current instruction index. 
    //   - This will force all previous load/store instructions to retire and flush to memory before allowing new ones. 
    //   - Once branch snapshots are implemented, these values can be stored in the snapshot to avoid a flush on every 
    //       branch misprediction. 
    // FENCE.I
    //   - When this instruction is queued, stall decode and instruction fetch and flush instruction fetch. 
    //   - Wait for all store instructions to be performed and retire, then invalidate the instruction cache. 
    //   - Afterwards, execution can resume. 
    // CSR 
    //   - Will be implemented in the MEM pipeline. 
    //   - CSR instructions that modify memory behavior are treated as fence instructions in decode. 
    // EBREAK / ECALL / Traps
    //   - Returns ebreak/ecall/ifetch traps directly to the ROB? 
    //   - Pause until all instructions in the ROB are retired.
    //   - Then execute the exception handler. 
    //   - tvec stores the jump offset to the trap handler. 
    //   - edeleg, ideleg stores which privilage level exceptions are delegated to (U, S, M). 
    //   - ip stores information on pending interrupts
    //   - ie stores interupt enable bits
    //   - scratch is a read/write register for general use for the trap handler. Typically stores context pointer. 
    //   - epc stores the program counter of the instruction that caused the trap.
    //   - cause stores the trap reason
    //   - tval stores additional information about the trap. 



endmodule 