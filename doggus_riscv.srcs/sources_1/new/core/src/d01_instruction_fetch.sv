// Module description: 
// RISCV d01 Instruction Fetch
// 
// Parameters: 
// XLEN:        Data width of the core.
// 
// Ports:
// clk:         System clock input.
// rst_n:       Active low reset input.
// wb_imem_if:  Wishbone instruction memory interface.
// pc_i:        Program counter input.
// req_i:       Request valid input.
// cancel_i:    Cancel current request.
// instr_o:     Instruction output.
// ready_o:     Instruction is ready.
// trap_cause_o: Trap cause output.
// 
// Dependencies:
// - None
// 
// Version: 01.00

`include "wishbone_if.svh"
`include "riscv_pkg.svh"
`include "datapath_pkg.svh"

module d01_instruction_fetch 
    import riscv_pkg::*;
    import datapath_pkg::*;
#(
    parameter logic C_EXTENSION = 1'b0
) (
    input logic clk, rst_n,

    // Wishbone interface
    wishbone_if.master wb_imem_if

    // Datapath control 
    input logic [ADDR_W-1:0] pc_i,
    input logic req_i,
    input logic cancel_i,
    output instr_t instr_o,
    output logic ready_o,
    output if_trap_cause_t trap_cause_o
);

if (wb_imem_if.WB_DATA_W % INSTR_W != 0) begin
    $fatal("wb_imem_if.WB_DATA_W must be a multiple of INSTR_W");
end


// --- Local parameters --- //

localparam int unsigned INSTR_IN_DATR = wb_imem_if.WB_DATA_W / INSTR_W; // Number of instructions per word in the wishbone data bus.
localparam WB_DAT_BYTEW = wb_imem_if.WB_DATA_W / 8; // Number of bytes per word in the wishbone data bus.


// --- Signals --- //

logic [wb_imem_if.WB_ADDR_W-1:0] wb_addr; // Byte address to wishbone address
logic [wb_imem_if.WB_ADDR_W-1:0] wb_addr_q; // Previous wishbone address.

logic req_changed; // Indicates if the request has changed since the last cycle.
logic req_q; // Previous request state.

logic req_ackd; // Indicates the current request is acknowledged.

logic [31:0] instr_buf [$clog2(INSTR_IN_DATR)-1:0]; // Read buffer for instructions.


// --- Module Logic --- //

// Previous request state register
assign wb_addr = (wb_imem_if.WB_ADDR_W)'(pc_i[WB_ADDR_W-1:WB_ADDR_W-$clog2(WB_DAT_BYTEW)]);
always_ff @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        req_q <= 1'b0;
        wb_addr_q <= '0;
    end
    // Don't update history if the wb bus is not ready to accept the next transaction 
    else if (!wb_imem_if.stall) begin
        req_q <= req_i;
        wb_addr_q <= wb_addr;
    end
end

// Detect posedge of req_i or wb_addr change. 
// Don't send request if the wb bus is not ready to accept the transaction. 
assign req_changed = !wb_imem_if.stall && req_i && (!req_q || wb_addr_q != wb_addr);

// Keep track of if the request is acknowledged or not. 
always_ff @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        req_ackd <= 1'b0;
    end 
    else begin
        if (req_changed || cancel_i) begin
            req_ackd <= 1'b0;
        end
        else if (wb_imem_if.ack) begin
            req_ackd <= 1'b1;
        end
    end
end

// Instruction read buffer
always_ff @(posedge clk, negedge rst_n) begin
    if (rst_n == 1'b0) begin
        instr_buf <= '{default: '0};
    end
    else if (cancel_i) begin
        instr_buf <= '{default: '0};
    end
    else if (wb_imem_if.ack) begin
        for (int i = 0; i < INSTR_IN_DATR; i++) begin
            if (i < $clog2(INSTR_IN_DATR)) begin
                instr_buf[i] <= wb_imem_if.datr[i*32 +: 32];
            end
        end
    end
end


// --- Wishbone assignments --- //

assign wb_imem_if.cyc = (req_changed || ~req_ackd) && req_i && !cancel_i;
assign wb_imem_if.stb = req_changed && req_i && !cancel_i;
assign wb_imem_if.adr = wb_addr;
assign wb_imem_if.we = 0;
assign wb_imem_if.datw = '0;
assign wb_imem_if.sel = '1;
assign wb_imem_if.mtag = '0;


// --- Datapath assignments --- //

// Use data from the data bus if the request is acknowledged, otherwise use the buffer.
if (INSTR_IN_DATR > 1) begin
    logic [INSTR_IN_DATR-1:0] instr_buf_sel;
    assign instr_buf_sel = pc_i[2 +: $clog2(INSTR_IN_DATR)];
    assign instr_o.raw_instr = wb_imem_if.ack ? wb_imem_if.datr[instr_buf_sel*32 +: 32] : instr_buf[instr_buf_sel];
    
end
else begin
    assign instr_o.raw_instr = wb_imem_if.ack ? wb_imem_if.datr[31:0] : instr_buf[0];
end

// The output is ready when the request is acknowledged and the request has not changed since the last cycle.
assign ready_o = wb_imem_if.ack || (req_ackd && !req_changed);


// --- Error assignment --- //
always_comb begin
    trap_cause_o = IF_TRAP_CAUSE_NONE;

    if (wb_imem_if.err) begin
        trap_cause_o = IF_TRAP_CAUSE_WISHBONE;
    end
    else if (C_EXTENSION == 1'b0 && pc_i[1:0] != 2'b00) begin
        trap_cause_o = IF_TRAP_CAUSE_INSTR_MISALIGN;
    end
    else if (C_EXTENSION == 1'b1 && pc_i[0] != 1'b0) begin
        trap_cause_o = IF_TRAP_CAUSE_INSTR_MISALIGN;
    end
end

endmodule