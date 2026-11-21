`ifndef WISHBONE_IF_SVH
`define WISHBONE_IF_SVH

interface wishbone_if #(
    parameter int unsigned WB_ADDR_W = 30,
    parameter int unsigned WB_DATA_W = 32,
    parameter int unsigned WB_TAG_W = 1
) (
    input logic clk, rst_n
);
    
// master -> slave
logic cyc;                      // Bus cycle is active. Stays high until every ACK has returned.
logic stb;                      // A request is being presented.
logic we;                       // 1 = write, 0 = read.
logic [WB_ADDR_W-1:0] adr;         // transaction address
logic [WB_DATA_W-1:0] datw;        // write data
logic [WB_DATA_W/8-1:0] sel;       // indicates which words of the DATA_W are being accessed.
logic [WB_TAG_W-1:0] mtag;         // master transaction tag
// slave -> master
logic stall;                    // Slave can't accept this request now.
logic ack;                      // One request completed.
logic err;                      // A request failed (use instead of ack).
logic [WB_DATA_W-1:0] datr;        // Read data, valid with ack.
logic [WB_TAG_W-1:0] stag;         // slavetransaction tag

modport master (
    output cyc, stb, we, adr, datw, sel, mtag,
    input  stall, ack, err, datr, stag
);

modport slave (
    input  cyc, stb, we, adr, datw, sel, mtag,
    output stall, ack, err, datr, stag
);

// Monitor modport: everything is an input, for checkers and debug
modport monitor (
    input cyc, stb, we, adr, datw, sel, mtag,
            stall, ack, err, datr, stag
);

// A request is accepted on this condition
wire accepted = cyc && stb && !stall;
    

endinterface

`endif