`default_nettype none

module top 
(
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
    logic [6:0] length;
    logic [3:0] displayOut, nextDisplayOut;
    logic button;
    logic [1:0] blinkToggle;
    logic goodCollButton, badCollButton;

    // BCD conversion using BCD adders
    logic [3:0] bcd_ones, bcd_tens, bcd_hundreds;
    
    
    score_posedge_detector posDetector2 (.clk(clk), .nRst(~rst), .goodColl_i(pb[0]), .badColl_i(pb[1]), .goodColl(goodCollButton), .badColl(badCollButton));
    // Score tracker instance
    score_tracker3 track1 (.clk(clk), .nRst(~rst), .goodColl(goodCollButton), .badColl(badCollButton), .dispScore(), .current_score(), .isGameComplete(isGameComplete), .bcd_ones(bcd_ones), .bcd_tens(bcd_tens), .bcd_hundreds(bcd_hundreds));

    // Toggle Screen
    toggle_screen toggle1(.displayOut(displayOut), .blinkToggle(blinkToggle), .clk(clk), .rst(rst), .bcd_ones(bcd_ones), .bcd_tens(bcd_tens), .bcd_hundreds(bcd_hundreds));
    // Display BCD digits on seven-segment displays with fast blinking
    ssdec ssdec1(.in(displayOut), .enable(blinkToggle == 1), .out(ss0[6:0]));
    ssdec ssdec2(.in(displayOut), .enable(blinkToggle == 2), .out(ss1[6:0]));
    ssdec ssdec3(.in(displayOut), .enable(blinkToggle == 0), .out(ss2[6:0]));
endmodule

// add badColl here to switch displays on and off if player loses
module toggle_screen (
    input logic clk, rst,
    input logic [3:0] bcd_ones, bcd_tens, bcd_hundreds,
    output logic [3:0] displayOut,
    output logic [1:0] blinkToggle
);
logic [1:0] nextBlinkToggle;
logic [3:0] nextDisplayOut;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        blinkToggle <= 2'b0;
        displayOut <= 0;
    end else begin
        blinkToggle <= nextBlinkToggle;
        displayOut <= nextDisplayOut;
    end
end

always_comb begin
    nextBlinkToggle = 2'b0;
    nextDisplayOut = 4'b0;

    if (blinkToggle < 2'd2) begin
        nextBlinkToggle = blinkToggle + 2'b1;
    end else begin
        nextBlinkToggle = 2'b0;
    end
    
    if (blinkToggle == 0) begin
        nextDisplayOut = bcd_ones;
    end else if (blinkToggle == 1) begin
        nextDisplayOut = bcd_tens;
    end else begin
        nextDisplayOut = bcd_hundreds;
    end
end
endmodule

module score_posedge_detector (
    input logic clk, nRst, goodColl_i, badColl_i,
    output logic goodColl, badColl
);

logic [1:0] N;
logic [1:0] sig_out;
logic [1:0] posEdge;

always_ff @(posedge clk, negedge nRst) begin
    if (~nRst) begin
        N <= 2'b0;
        sig_out <= 2'b0;
    end else begin
        N <= {goodColl_i, badColl_i};
        sig_out <= N;
    end
end
assign posEdge = N & ~sig_out;
assign goodColl = posEdge[1];
assign badColl = posEdge[0];

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
      out = 7'b0000000;
    end
end

endmodule

module score_tracker3(
    input logic clk, nRst, goodColl, badColl,
    output logic [7:0] current_score,
    output logic [7:0] dispScore,
    output logic [3:0] bcd_ones, bcd_tens, bcd_hundreds,
    output logic isGameComplete
);
    logic [7:0] nextCurrScore, nextHighScore, maxScore, deconcatenate;
    logic [7:0] currScore, highScore, nextDispScore;
    logic isGameComplete_nxt, last_collision, current_collision;
    logic [3:0] carry, next_bcd_ones, next_bcd_tens, next_bcd_hundreds;
    assign maxScore = 8'd140;
   
    always_ff @(posedge clk, negedge nRst) begin
        if (~nRst) begin
            currScore <= 8'b0;
            highScore <= 8'b0;
            dispScore <= 8'b0;
            //isGameComplete <= 1'b0;
            bcd_ones <= 0;
            bcd_tens <= 0;
            bcd_hundreds <= 0;
            last_collision <= 0;
        end else begin
            currScore <= nextCurrScore;
            highScore <= nextHighScore;
            //isGameComplete <= isGameComplete_nxt;
            dispScore <= nextDispScore;
            bcd_ones <= next_bcd_ones;
            bcd_tens <= next_bcd_tens;
            bcd_hundreds <= next_bcd_hundreds;
            last_collision <= current_collision;
        end
    end

    always_comb begin
        nextCurrScore = currScore;
        isGameComplete = 1'b0;
        nextHighScore = highScore;
        next_bcd_ones = bcd_ones;
        next_bcd_tens = bcd_tens;
        next_bcd_hundreds = bcd_hundreds;
        deconcatenate = 0;
        current_collision = last_collision;
        
        if (goodColl && last_collision == 0) begin
            isGameComplete = 1'b0;
            nextCurrScore = currScore + 1;
            current_collision = 1;
            
            if (nextCurrScore > 139) begin
                next_bcd_tens= 1;
                next_bcd_hundreds = 1;
            end
            else if (nextCurrScore > 129) begin
                deconcatenate = nextCurrScore - 130;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 3;
                next_bcd_hundreds = 1;
            end
            else if (nextCurrScore > 119) begin
                deconcatenate = nextCurrScore - 120;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 2;
                next_bcd_hundreds = 1;
            end
            else if (nextCurrScore > 109) begin
                deconcatenate = nextCurrScore - 110;
                next_bcd_ones = deconcatenate[3:0];
            end
            else if (nextCurrScore > 99) begin
                deconcatenate = nextCurrScore - 100;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 0;
                next_bcd_hundreds = 1;
            end
            else if (nextCurrScore > 89) begin
                deconcatenate = nextCurrScore - 90;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 9;
                next_bcd_hundreds = 0;
            end
            else if (nextCurrScore > 79) begin
                deconcatenate = nextCurrScore - 80;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 8;
                next_bcd_hundreds = 0;
            end
            else if (nextCurrScore > 69) begin
                deconcatenate = nextCurrScore - 70;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 7;
                next_bcd_hundreds = 0;
            end
            else if (nextCurrScore > 59) begin
                deconcatenate = nextCurrScore - 60;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 6;
                next_bcd_hundreds = 0;
            end
            else if (nextCurrScore > 49) begin
                deconcatenate = nextCurrScore - 50;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 5;
                next_bcd_hundreds = 0;
            end
            else if (nextCurrScore > 39) begin
                deconcatenate = nextCurrScore - 40;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens = 4;
                next_bcd_hundreds = 0;
            end
            else if (nextCurrScore > 29) begin
                deconcatenate = nextCurrScore - 30;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 3;
                next_bcd_hundreds = 0;
            end
            else if (nextCurrScore > 19) begin
                deconcatenate = nextCurrScore - 20;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens = 2;
                next_bcd_hundreds = 0;
            end
            else if (nextCurrScore > 9) begin
                deconcatenate = nextCurrScore - 10;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens = 1;
                next_bcd_hundreds = 0;
            end else begin
                deconcatenate = nextCurrScore;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens = 0;
                next_bcd_hundreds = 0;
            end
            if (nextCurrScore > nextHighScore) begin
                nextHighScore = nextCurrScore;
            end
        end
        if (badColl || currScore >= maxScore) begin
            nextCurrScore = 0;
            isGameComplete = 1'b1;

            if (nextHighScore > 139) begin
                deconcatenate = nextHighScore - 140;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 4;
                next_bcd_hundreds = 1;
            end
            else if (nextHighScore > 129) begin
                deconcatenate = nextHighScore - 130;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 3;
                next_bcd_hundreds = 1;
            end
            else if (nextHighScore > 119) begin
                deconcatenate = nextHighScore - 120;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 2;
                next_bcd_hundreds = 1;
            end
            else if (nextHighScore > 109) begin
                deconcatenate = nextHighScore - 110;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 1;
                next_bcd_hundreds = 1;
            end
            else if (nextHighScore > 99) begin
                deconcatenate = nextHighScore - 100;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 0;
                next_bcd_hundreds = 1;
            end
            else if (nextHighScore > 89) begin
                deconcatenate = nextHighScore - 90;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 9;
                next_bcd_hundreds = 0;
            end
            else if (nextHighScore > 79) begin
                deconcatenate = nextHighScore - 80;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 8;
                next_bcd_hundreds = 0;
            end
            else if (nextHighScore > 69) begin
                deconcatenate = nextHighScore - 70;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 7;
                next_bcd_hundreds = 0;
            end
            else if (nextHighScore > 59) begin
                deconcatenate = nextHighScore - 60;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 6;
                next_bcd_hundreds = 0;
            end
            else if (nextHighScore > 49) begin
                deconcatenate = nextHighScore - 50;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 5;
                next_bcd_hundreds = 0;
            end
            else if (nextHighScore > 39) begin
                deconcatenate = nextHighScore - 40;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens = 4;
                next_bcd_hundreds = 0;
            end
            else if (nextHighScore > 29) begin
                deconcatenate = nextHighScore - 30;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens= 3;
                next_bcd_hundreds = 0;
            end
            else if (nextHighScore > 19) begin
                deconcatenate = nextHighScore - 20;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens = 2;
                next_bcd_hundreds = 0;
            end
            else if (nextHighScore > 9) begin
                deconcatenate = nextHighScore - 10;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens = 1;
                next_bcd_hundreds = 0;
            end else begin
                deconcatenate = nextHighScore;
                next_bcd_ones = deconcatenate[3:0];
                next_bcd_tens = 0;
                next_bcd_hundreds = 0;
            end
        end
        if(goodColl == 0 || last_collision == 1) begin
            current_collision = 0;
        end
        if (!isGameComplete_nxt) begin
                nextDispScore = nextCurrScore;
            end else begin
                nextDispScore = nextHighScore;
            if (nextCurrScore > nextHighScore) begin
                nextHighScore = nextCurrScore;
            end
        end
    end

    assign current_score = currScore;
endmodule

