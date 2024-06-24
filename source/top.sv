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
    logic clk, nRst;
    assign clk = hz100;
    assign nRst = reset;
    logic isGameComplete;
    logic [6:0] dispScore;
    logic blinkToggle;

    // Blinking timer
    reg [22:0] blinkCounter = 0;

    // Clock divider for fast blinking
    always @(posedge clk or negedge nRst) begin
        if (~nRst) begin
            blinkCounter <= 0;
            blinkToggle <= 1'b0;
        end else if (blinkCounter == 100) begin // Adjust this value for faster blink
            blinkToggle <= ~blinkToggle;
            blinkCounter <= 0;
        end else begin
            blinkCounter <= blinkCounter + 1;
        end
    end

    // Score tracker instance
    score_tracker track1 (.clk(clk), .nRst(nRst), .goodColl(pb[0]), .badColl(pb[1]), .dispScore(dispScore), .isGameComplete(isGameComplete));

    // Display score on ssdec1 and ssdec2 with fast blinking
    ssdec ssdec1(.in(dispScore[3:0]), .enable(blinkToggle), .out(ss0[6:0]));
    ssdec ssdec2(.in({1'b0, dispScore[6:4]}), .enable(blinkToggle), .out(ss1[6:0]));

endmodule
