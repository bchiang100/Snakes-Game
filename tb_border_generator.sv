/*
    Module Name: tb_border_snakes.sv
    Description: Test bench for border_generator module
*/

`timescale 1ms / 100us

module tb_border_generator ();

    // Enum for mode types
    typedef enum logic {
    OFF = 1'b0,
    ON = 1'b1
    } MODE_TYPES;

    // Testbench parameters
    localparam CLK_PERIOD = 10; // 100 Hz clk
    logic tb_checking_outputs; 
    integer tb_test_num;
    string tb_test_case;

    // DUT ports
    logic [3:0] tb_x, tb_y;
    logic tb_isBorder;
    logic exp_isBorder; // Expected isBorder output

    // Task to check border output
    task check_border;
    input logic [3:0] exp_tb_x, exp_tb_y; 
    input logic exp_isBorder; // Expected border status

    begin
        tb_checking_outputs = 1'b1;

        tb_x = exp_tb_x;
        tb_y = exp_tb_y;
        #1; // Wait for the DUT to process inputs

        if(tb_isBorder == exp_isBorder)
            $info("Correct border output: x=%0d, y=%0d, expected=%0d, actual=%0d", exp_tb_x, exp_tb_y, exp_isBorder, tb_isBorder);
        else
            $error("Incorrect border output: x=%0d, y=%0d, expected=%0d, actual=%0d", exp_tb_x, exp_tb_y, exp_isBorder, tb_isBorder); 

        tb_checking_outputs = 1'b0;  
    end
    endtask

    // DUT Portmap
    border_generator DUT(.x(tb_x), .y(tb_y), .isBorder(tb_isBorder)); 

    // Main Test Bench Process
    initial begin
        // Signal dump
        $dumpfile("dump.vcd");
        $dumpvars; 

        // Initialize test bench signals
        tb_x = 4'b0;
        tb_y = 4'b0;
        tb_checking_outputs = 1'b0;
        tb_test_num = 0;

        // ************************************************************************
        // Test Case 0: Check all coordinates and its borders
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 0: Check isBorder";
        $display("\n\n%s", tb_test_case);

        for (integer i = 0; i < 16; i++) begin
            for (integer j = 0; j < 12; j++) begin
                if (i == 0 || i == 15 || j == 0 || j == 11) begin
                    exp_isBorder = 1'b1;
                end else begin
                    exp_isBorder = 1'b0;
                end
                check_border(i, j, exp_isBorder);
            end
        end
        
        $finish;
    end
endmodule