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
  logic clk, nRst;
  assign clk = hz100;
  assign nRst = reset;
  logic mode;
  logic isGameComplete;
  logic [6:0] dispScore;
  task switch;
    assign mode = 1'b1;
    #(0.001);
    assign mode = 1'b0;
    #(0.001);
  endtask

  score_tracker track1 (.clk(clk), .nRst(nRst), .goodColl(pb[0]), .badColl(pb[1]), .dispScore(dispScore), .isGameComplete(isGameComplete));
  ssdec ssdec1(.in(dispScore[3:0]), .enable(mode), .out(ss0[0:6]));
  ssdec ssdec2(.in({1'b0, dispScore[6:4]}), .enable(mode), .out(ss0[0:6]));
endmodule
