`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2026 09:51:16 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    // FPGA config flash
    output logic fpga_flash_cs_b_o,
    inout logic fpga_flash_d0_o,
    inout logic fpga_flash_d1_io,
    inout logic fpga_flash_d2_io,
    inout logic fpga_flash_d3_io,
    
    // Control signals
    input logic fpga_reset_n_i,
    input logic cpu_reset_n_i,
    input logic pwr_btn_n_i,

    // Status signal
    output logic system_hb_led,
    output logic cpu_hb_led,
    output logic [3:0] dbg_led,

    // Memory 0
    output logic [1:0] hyperram0_cs_o,
    output logic hyperram0_ck_o,
    output logic hyperram0_ckn_o,
    output logic hyperram0_reset_n_o,
    inout logic hyperram0_rwds_io,
    inout logic [7:0] hyperram0_dq_io,

    // Memory 1
    output logic [1:0] hyperram1_cs_o,
    output logic hyperram1_ck_o,
    output logic hyperram1_ckn_o,
    output logic hyperram1_reset_n_o,
    inout logic hyperram1_rwds_io,
    inout logic [7:0] hyperram1_dq_io,

    // Memory 2 
    output logic [1:0] hyperram2_cs_o,
    output logic hyperram2_ck_o,
    output logic hyperram2_ckn_o,
    output logic hyperram2_reset_n_o,
    inout logic hyperram2_rwds_io,
    inout logic [7:0] hyperram2_dq_io,

    // Memory 3
    output logic [1:0] hyperram3_cs_o,
    output logic hyperram3_ck_o,
    output logic hyperram3_ckn_o,
    output logic hyperram3_reset_n_o,
    inout logic hyperram3_rwds_io,
    inout logic [7:0] hyperram3_dq_io,

    // SPI flash
    output logic [1:0] strg_cs_o,
    output logic strg_clk_o,
    inout logic strg_d0_io,
    inout logic strg_d1_io,
    inout logic strg_d2_io,
    inout logic strg_d3_io,

    // SD Card
    output logic strg_clk_o,
    inout logic strg_cmd_o,
    inout logic strg_d0_io,
    inout logic strg_d1_io,
    inout logic strg_d2_io,
    inout logic strg_d3_io,

    // UART 0 (system)
    output logic uart0_tx_o,
    input logic uart0_rx_i,

    // UART 1 
    output logic uart1_tx_o,
    input logic uart1_rx_i,

    // UART 2
    output logic uart2_tx_o,
    input logic uart2_rx_i,

    // I2C 0 
    inout logic i2c0_scl_io,
    inout logic i2c0_sda_io,

    // I2C 1
    inout logic i2c1_scl_io,
    inout logic i2c1_sda_io,

    // USB 0
    inout logic usb0_dp_o,
    inout logic usb0_dn_o,

    // USB 1
    inout logic usb1_dp_o,
    inout logic usb1_dn_o,

    // GPIO 0
    inout logic [15:0] gpio0_io,

    // GPIO 1
    inout logic [15:0] gpio1_io,

    // GPI 2
    input logic [15:0] gpi2_i,

    // LED array (16 LEDs)
    output logic shift_led_clk_o,
    output logic shift_led_dat_o,
    output logic shift_led_latch_o,
    output logic shift_led_oe_o,

    // 7-segment display (2 digits, 8 bits each)
    output logic shift_7seg_clk_o,
    output logic shift_7seg_dat_o,
    output logic shift_7seg_latch_o,
    output logic shift_7seg_oe_o
);

// CCLK access for fpga flash
logic fpga_flash_clk_o;
STARTUPE2 #(
    .PROG_USR("FALSE"),  // Activate program event security feature. Requires encrypted bitstreams.
    .SIM_CCLK_FREQ(0.0)  // Set the Configuration Clock Frequency(ns) for simulation.
)
STARTUPE2_inst (
    .CFGCLK(),                      // 1-bit output: Configuration main clock output
    .CFGMCLK(),                     // 1-bit output: Configuration internal oscillator clock output
    .EOS(),                         // 1-bit output: Active high output signal indicating the End Of Startup.
    .PREQ(),                        // 1-bit output: PROGRAM request to fabric output
    .CLK(1'b0),                     // 1-bit input: User start-up clock input
    .GSR(1'b0),                     // 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
    .GTS(1'b0),                     // 1-bit input: Global 3-state input (GTS cannot be used for the port name)
    .KEYCLEARB(1'b1),               // 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
    .PACK(1'b0),                    // 1-bit input: PROGRAM acknowledge input
    .USRCCLKO(fpga_flash_clk_o),    // 1-bit input: User CCLK input
                                    // For Zynq-7000 devices, this input must be tied to GND
    .USRCCLKTS(1'b0),               // 1-bit input: User CCLK 3-state enable input
                                    // For Zynq-7000 devices, this input must be tied to VCC
    .USRDONEO(1'b1),                // 1-bit input: User DONE pin output control
    .USRDONETS(1'b1)                // 1-bit input: User DONE 3-state enable output
);				
			

endmodule
