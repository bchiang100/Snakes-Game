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
