/*
    Module Name: tb_dac_counter.sv
    Description: Test bench for DAC counter
*/

`timescale 1ns / 10ps

module tb_dac_counter ();


    // Testbench parameters
    localparam CLK_PERIOD = 10; // 100 Hz clk
    logic tb_checking_outputs; 
    integer tb_test_num;
    string tb_test_case;

    // DUT ports
    logic tb_clk, tb_nRst_i;
    logic tb_at_max;
    logic [7:0] tb_dacCount;


    // Reset DUT Task
    task reset_dut;
        @(negedge tb_clk);
        tb_nRst_i = 1'b0; 
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_nRst_i = 1'b1;
        @(posedge tb_clk);
    endtask

    task check_dacCount;
    input logic [7:0] exp_dacCount; 
    begin
        @(negedge tb_clk);
        tb_checking_outputs = 1'b1;
        if(tb_dacCount == exp_dacCount)
            $info("Correct count: %0d.", exp_dacCount);
        else
            $error("Incorrect count. Expected: %0d. Actual: %0d.", exp_dacCount, tb_dacCount); 
        #(1);
        tb_checking_outputs = 1'b0;  
    end
    endtask

    // Clock generation block
    always begin
        tb_clk = 1'b0; 
        #(CLK_PERIOD / 2.0);
        tb_clk = 1'b1; 
        #(CLK_PERIOD / 2.0); 
    end

    // DUT Portmap
    dac_counter DUT(.clk(tb_clk),
                .nRst(tb_nRst_i),
                .at_max(tb_at_max),
                .dacCount(tb_dacCount));

    // Main Test Bench Process
    initial begin
        // Signal dump
        $dumpfile("dump.vcd");
        $dumpvars; 

        // Initialize test bench signals
        tb_nRst_i = 1'b1;
        tb_at_max = 1'b0;
        tb_checking_outputs = 1'b0;
        tb_test_num = -1;
        tb_test_case = "Initializing";

        // Wait some time before starting first test case
        #(0.1);

        // ************************************************************************
        // Test Case 0: Power-on-Reset of the DUT
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 0: Power-on-Reset of the DUT";
        $display("\n\n%s", tb_test_case);

        tb_nRst_i = 1'b0;  // activate reset

        // Wait for a bit before checking for correct functionality
        #(2);
        
        check_dacCount(8'b0);

        // Check that the reset value is maintained during a clock cycle
        @(negedge tb_clk);

        check_dacCount(8'b0);

        // Release the reset away from a clock edge
        @(negedge tb_clk);
        tb_nRst_i  = 1'b1;   // Deactivate the chip reset
        // Check that internal state was correctly keep after reset release

        check_dacCount(8'b0);

        // ************************************************************************
        // Test Case 1: Test DAC Counter
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 1: Test DAC Counter";
        reset_dut;
        $display("\n\n%s", tb_test_case);

        tb_at_max = 1'b1;
        #(CLK_PERIOD * 25);
       

        tb_at_max = 1'b0;
        #(CLK_PERIOD);
        check_dacCount(8'b0);

        // ************************************************************************
        // Test Case 2: Test Continuous Counting
        // ************************************************************************
        tb_test_num += 2;
        tb_test_case = "Test Case 2: Test Continuous Counting";
        reset_dut;
        $display("\n\n%s", tb_test_case);
        
        tb_at_max = 1'b1;
        #(CLK_PERIOD * 300);

        tb_at_max = 1'b0;
        check_dacCount(8'b0);
        
        $finish; 
    end

endmodule 