// FPGA Top Level

`default_nettype none

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);
  logic clk, rst;
  logic [2:0] state;
  logic [4:0] timeCounter;
  assign clk = hz100;
  assign rst = reset;
  
  stop_watch stopwatch1 (.clk(clk), .nRst_i(~pb[19]), .button_i(pb[0]), .mode_o(state), .time_o(timeCounter));

  // temporarily simulates stopwatch without SSDEC
  assign left[2:0] = state;
  assign right[4:0] = timeCounter;

endmodule
