`default_nettype none

module top (
    // I/O ports
    input logic hz100, reset,
    input logic [20:0] pb,
    output logic [7:0] left, right,
           ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
    output logic red, green, blue,

    // UART ports
    output logic [7:0] txdata,
    input logic [7:0] rxdata,
    output logic txclk, rxclk,
    input logic txready, rxready
);
    logic clk, rst;
    logic goodColl_i, badColl_i, toggleMode_i;
    logic goodColl, badColl, toggleMode;

    logic [3:0] direction_i;
    logic [3:0] newDirection;

    logic [8:0] freq;

    assign clk = hz100;
    assign rst = reset;
    assign direction_i = {pb[13], pb[5], pb[8], pb[10]};
    assign goodColl_i = pb[0];
    assign badColl_i = pb[1];
    assign toggleMode_i = pb[2];


    posedge_detector posDetector1 (.clk(clk), .nRst(~rst), .button_i(toggleMode_i), .button(toggleMode), .goodColl_i(goodColl_i), .badColl_i(badColl_i), .direction_i(direction_i), .goodColl(goodColl), .badColl(badColl), .direction(newDirection));
    freq_selector freq1 (.freq(freq), .goodColl_i(goodColl_i), .badColl_i(badColl_i), .direction_i(direction_i));

endmodule;


module posedge_detector (
    input logic clk, nRst, goodColl_i, badColl_i, button_i,
    input logic [3:0] direction_i,
    output logic goodColl, badColl, button,
    output logic [3:0] direction
);

logic [6:0] N;
logic [6:0] sig_out;
logic [6:0] posEdge;

always_ff @(posedge clk, negedge nRst) begin
    if (~nRst) begin
        N <= 7'b0;
        sig_out <= 7'b0;
    end else begin
        N <= {goodColl_i, badColl_i, button_i, direction_i};
        sig_out <= N;
    end
end
assign posEdge = N & ~sig_out;

assign goodColl = posEdge[6];
assign badColl = posEdge[5];
assign button = posEdge[4];
assign direction = posEdge[3:0];

endmodule

module freq_selector(
    input logic goodColl_i, badColl_i, 
    input logic [3:0] direction_i,
    output logic [8:0] freq
);

always_comb begin
    freq = 0;
    if (goodColl_i)
        freq = 9'd440; // A
    if (badColl_i)
        freq = 9'd311; // D Sharp
    if (|direction_i)
        freq = 9'd262; // C
end

endmodule