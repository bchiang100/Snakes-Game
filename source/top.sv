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
    assign clk = hz100;
    assign rst = reset;
    logic isGameComplete;
    logic [6:0] dispScore;
    logic [3:0] displayOut, nextDisplayOut;
    logic button;
    logic goodCollButton, badCollButton;

// Blinking timer
logic blinkToggle, nextBlinkToggle;

// Clock divider for fast blinking
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        blinkToggle <= 1'b0;
        displayOut <= 0;
    end else begin
        blinkToggle <= nextBlinkToggle;
        displayOut <= nextDisplayOut;
    end
end

always_comb begin
    nextBlinkToggle = 1'b0;
    nextDisplayOut = 4'b0;

    nextBlinkToggle = ~blinkToggle;

    if (~blinkToggle) begin
        nextDisplayOut = bcd_ones;
    end else begin
        nextDisplayOut = bcd_tens;
    end
end
    posedge_detector posDetector1 (.clk(clk), .nRst(~rst), .button_i(pb[0]), .button(goodCollButton), .goodColl_i(1'b0), .badColl_i(1'b0), .direction_i(4'b0), .goodColl(), .badColl(), .direction());
    posedge_detector posDetector2 (.clk(clk), .nRst(~rst), .button_i(pb[1]), .button(badCollButton), .goodColl_i(1'b0), .badColl_i(1'b0), .direction_i(4'b0), .goodColl(), .badColl(), .direction());
    // Score tracker instance
    score_tracker track1 (.clk(clk), .nRst(~rst), .goodColl(goodCollButton), .badColl(badCollButton), .dispScore(dispScore), .isGameComplete(isGameComplete));
  
    // BCD conversion using BCD adders
    logic [3:0] bcd_ones, bcd_tens;
    logic cout_bcd1;

    // Convert the lower 4 bits of dispScore to BCD
    bcd_adder bcd_adder1 (.A(dispScore[3:0]), .B(4'b0000), .Cin(1'b0), .Cout_bcd(cout_bcd1), .Sum(bcd_ones));

    // Convert the upper 3 bits of dispScore and carry from the lower 4 bits
    bcd_adder bcd_adder2 (.A({1'b0, dispScore[6:4]}), .B({3'b000, cout_bcd1}), .Cin(1'b0), .Cout_bcd(), .Sum(bcd_tens));

    // Display BCD digits on seven-segment displays with fast blinking
    ssdec ssdec1(.in(displayOut), .enable(blinkToggle), .out(ss0[6:0]));
    ssdec ssdec2(.in(displayOut), .enable(~blinkToggle), .out(ss1[6:0]));
endmodule

module bcd_adder (
    input logic [3:0] A, B,  // 4-bit BCD inputs
    input logic Cin,         // Carry input
    output logic Cout_bcd,   // BCD carry output
    output logic [3:0] Sum   // 4-bit BCD sum output
);
    logic [4:0] Sum_temp;    // Temporary 5-bit sum including carry

    // Calculate the sum with carry-in
    assign Sum_temp = A + B + {4'b0, Cin};

    // Check if the sum exceeds BCD limit (9)
    always_comb begin
        if (Sum_temp > 9) begin
            Sum = Sum_temp[3:0] - 4'd10;  // Adjust sum to BCD
            Cout_bcd = 1;         // Set BCD carry
        end else begin
            Sum = Sum_temp[3:0];  // Keep sum as is
            Cout_bcd = 0;         // No BCD carry
        end
    end
endmodule

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

module ssdec (
input logic [3:0] in,
input logic enable,
output logic [6:0] out
);
always_comb begin
  case(in)
    4'b0000: begin out = 7'b0111111; end
    4'b0001: begin out = 7'b0000110; end
    4'b0010: begin out = 7'b1011011; end
    4'b0011: begin out = 7'b1001111; end
    4'b0100: begin out = 7'b1100110; end
    4'b0101: begin out = 7'b1101101; end
    4'b0110: begin out = 7'b1111101; end
    4'b0111: begin out = 7'b0000111; end
    4'b1000: begin out = 7'b1111111; end
    4'b1001: begin out = 7'b1100111; end
    4'b1010: begin out = 7'b1110111; end
    4'b1011: begin out = 7'b1111100; end
    4'b1100: begin out = 7'b0111001; end
    4'b1101: begin out = 7'b1011110; end
    4'b1110: begin out = 7'b1111001; end
    4'b1111: begin out = 7'b1110001; end
    default: begin out = '0; end
    endcase
        if (~enable) begin
            out = 7'b0;
        end
end

endmodule

module score_tracker(
    input logic clk, nRst, goodColl, badColl,
    output logic [6:0] dispScore,
    output logic isGameComplete
);
    logic [6:0] nextCurrScore, nextHighScore, maxScore;
    logic [6:0] currScore, highScore, nextDispScore;
    logic isGameComplete_nxt;

    assign maxScore = 7'd50;
   
    always_ff @(posedge clk, negedge nRst) begin
        if (~nRst) begin
            currScore <= 7'b0;
            highScore <= 7'b0;
            dispScore <= 7'b0;
            isGameComplete <= 1'b0;
        end else begin
            currScore <= nextCurrScore;
            highScore <= nextHighScore;
            isGameComplete <= isGameComplete_nxt;
            dispScore <= nextDispScore;
        end
    end

    always_comb begin
        nextCurrScore = currScore;
        isGameComplete_nxt = isGameComplete;
        nextHighScore = highScore;
        if (goodColl) begin
            isGameComplete_nxt = 1'b0;
            nextCurrScore = currScore + 1;
            if (nextCurrScore > nextHighScore) begin
                nextHighScore = nextCurrScore;
            end
        end
        if (badColl || currScore >= maxScore) begin
            nextCurrScore = 0;
            isGameComplete_nxt = 1'b1;
        end
        if (!isGameComplete_nxt) begin
                nextDispScore = nextCurrScore;
            end else begin
                nextDispScore = nextHighScore;
            end
    end
endmodule
