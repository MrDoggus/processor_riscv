`ifndef DATAPATH_PKG_SVH
`define DATAPATH_PKG_SVH

package datapath_pkg;

// Errors caused by instruction fetch.
parameter int unsigned IF_TRAP_CAUSE_W = 2;
typedef enum logic [IF_TRAP_CAUSE_W-1:0] {
    IF_TRAP_CAUSE_NONE = 0,
    IF_TRAP_CAUSE_INSTR_MISALIGN = 1,
    IF_TRAP_CAUSE_WISHBONE = 2
} if_trap_cause_t;

endpackage

`endif