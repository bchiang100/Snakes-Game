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
logic [22:0] blinkCounter = 0;

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

    // BCD conversion using BCD adders
    logic [3:0] bcd_ones, bcd_tens;
    logic cout_bcd1;

    // Convert the lower 4 bits of dispScore to BCD
    bcd_adder bcd_adder1 (.A(dispScore[3:0]), .B(4'b0000), .Cin(1'b0), .Cout_bcd(cout_bcd1), .Sum(bcd_ones));

    // Convert the upper 3 bits of dispScore and carry from the lower 4 bits
    bcd_adder bcd_adder2 (.A({1'b0, dispScore[6:4]}), .B({3'b000, cout_bcd1}), .Cin(1'b0), .Cout_bcd(), .Sum(bcd_tens));

    // Display BCD digits on seven-segment displays with fast blinking
    ssdec ssdec1(.in(bcd_ones), .enable(blinkToggle), .out(ss0[6:0]));
    ssdec ssdec2(.in(bcd_tens), .enable(blinkToggle), .out(ss1[6:0]));
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
end

endmodule

