`ifndef WISHBONE_IF_VH
`define WISHBONE_IF_VH

interface wishbone_if #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32
    parameter int unsigned WORD_W = 8
) (
    input logic clk, rst_n
);
    
// master -> slave
logic cyc;                      // Bus cycle is active. Stays high until every ACK has returned.
logic stb;                      // A request is being presented.
logic we;                       // 1 = write, 0 = read.
logic [ADDR_W-1:0] adr;         // transaction address
logic [DATA_W-1:0] datw;        // write data
logic [DATA_W/WORD_W-1:0] sel;  // indicates which words of the DATA_W are being accessed.
// slave -> master
logic stall;                    // Slave can't accept this request now.
logic ack;                      // One request completed.
logic err;                      // A request failed (use instead of ack).
logic [DATA_W-1:0] datr;        // Read data, valid with ack.

modport master (
    input  clk, rst,
    output cyc, stb, we, adr, datw, sel,
    input  stall, ack, err, datr
);

modport slave (
    input  clk, rst,
    input  cyc, stb, we, adr, datw, sel,
    output stall, ack, err, datr
);

// Monitor modport: everything is an input, for checkers and debug
modport monitor (
    input clk, rst, cyc, stb, we, adr, datw, sel,
            stall, ack, err, datr
);

// A request is accepted on this condition
wire accepted = cyc && stb && !stall;
    

endinterface

`endif