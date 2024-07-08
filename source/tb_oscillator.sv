/*
    Module Name: tb_oscillator.sv
    Description: Test bench for sound oscillator
*/

`timescale 1ns / 10ps

module tb_oscillator ();

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
    logic tb_clk, tb_nRst_i;
    logic tb_goodColl;
    logic tb_badColl;
    logic tb_at_max;


    // Reset DUT Task
    task reset_dut;
        @(negedge tb_clk);
        tb_nRst_i = 1'b0; 
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_nRst_i = 1'b1;
        @(posedge tb_clk);
    endtask

    // Task to check sound toggle output
    task check_at_max;
    input logic exp_at_max; 
    begin
        @(negedge tb_clk);
        tb_checking_outputs = 1'b1;
        if(tb_at_max == exp_at_max)
            $info("Correct at_max: %0d.", exp_at_max);
        else
            $error("Incorrect status. Expected: %0d. Actual: %0d.", exp_at_max, tb_at_max); 
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
    oscillator DUT(.clk(tb_clk),
                .nRst(tb_nRst_i),
                .at_max(tb_at_max),
                .goodColl(tb_goodColl),
                .badColl(tb_badColl));

    // Main Test Bench Process
    initial begin
        // Signal dump
        $dumpfile("dump.vcd");
        $dumpvars; 

        // Initialize test bench signals
        tb_nRst_i = 1'b1;
        tb_goodColl = 1'b0;
        tb_badColl = 1'b0;
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
        
        check_at_max(1'b0);

        // Check that the reset value is maintained during a clock cycle
        @(negedge tb_clk);
        check_at_max(1'b0);

        // Release the reset away from a clock edge
        @(negedge tb_clk);
        tb_nRst_i  = 1'b1;   // Deactivate the chip reset
        // Check that internal state was correctly keep after reset release
        check_at_max(1'b0);

        // ************************************************************************
        // Test Case 1: Test Good Collision
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 1: Test Good Collision";
        reset_dut;
        #(CLK_PERIOD); // allow for some delay
        $display("\n\n%s", tb_test_case);

        tb_goodColl = 1'b1;
        #(CLK_PERIOD * 5);
        tb_goodColl = 1'b0;
       

        #(CLK_PERIOD * 500);
       

        // ************************************************************************
        // Test Case 2: Test Bad Collision
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 2: Test Bad Collision";
        reset_dut;
        #(CLK_PERIOD); // allow for some delay
        $display("\n\n%s", tb_test_case);

        tb_badColl = 1'b1;
        #(CLK_PERIOD * 5);
        tb_badColl = 1'b0;
       

        #(CLK_PERIOD * 500);

$finish; 
    end
endmodule 