/*
    Module Name: tb_score_tracker.sv
    Description: Test bench for score tracker module
*/

`timescale 1ns / 10ps

module tb_score_tracker ();

    // Testbench parameters
    localparam CLK_PERIOD = 10; // 100 Hz clk
    logic tb_checking_outputs; 
    integer tb_test_num;
    string tb_test_case;

    // DUT ports
    logic tb_clk, tb_nRst_i;
    logic tb_goodColl, tb_badColl;
    logic [6:0] tb_currScore, tb_highScore;
    logic tb_isGameComplete;


    // Reset DUT Task
    task reset_dut;
        @(negedge tb_clk);
        tb_nRst_i = 1'b0; 
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_nRst_i = 1'b1;
        @(posedge tb_clk);
    endtask
    
// Task to check current score output
    task check_currentScore;
    input logic[6:0] exp_currScore; 
    begin
        @(negedge tb_clk);
        tb_checking_outputs = 1'b1;
        if(tb_currScore == exp_currScore)
            $info("Correct current score: %0d.", exp_currScore);
        else
            $error("Incorrect current score. Expected: %0d. Actual: %0d.", exp_currScore, tb_currScore); 
        
        #(1);
        tb_checking_outputs = 1'b0;  
    end
    endtask

    // Task to check high score output
    task check_highScore;
    input logic[6:0] exp_highScore; 
    begin
        @(negedge tb_clk);
        tb_checking_outputs = 1'b1;
        if(tb_highScore == exp_highScore)
            $info("Correct high score: %0d.", exp_highScore);
        else
            $error("Incorrect high score. Expected: %0d. Actual: %0d.", exp_highScore, tb_highScore); 
        
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
    score_tracker DUT(.clk(tb_clk),
                .nRst(tb_nRst_i),
                .goodColl(tb_goodColl),
                .badColl(tb_badColl),
                .currScore(tb_currScore),
                .highScore(tb_highScore),
                .isGameComplete(tb_isGameComplete)); 

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
        check_currentScore('0);
        check_highScore('0);

        // Check that the reset value is maintained during a clock cycle
        @(negedge tb_clk);
        check_currentScore('0);
        check_highScore('0);


        // ************************************************************************
        // Test Case 1: Updating currentScore and highScore
        // ************************************************************************
        tb_test_num += 1;
        reset_dut;
        #(CLK_PERIOD); // allow for some delay
        tb_test_case = "Test Case 1: Updating currentScore and highScore";
        $display("\n\n%s", tb_test_case);

        // Snake eats apple #1
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'b1); 
        check_highScore(7'b1); 

        // Snake eats apple #2
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'd2); 
        check_highScore(7'd2); 

        // Snake eats apple #3
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'd3); 
        check_highScore(7'd3); 

        // Snake eats apple #4
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'd4); 
        check_highScore(7'd4); 
 
        // ************************************************************************
        // Test Case 2: Testing badColl
        // ************************************************************************
        tb_test_num += 1;
        reset_dut;
        #(CLK_PERIOD); // allow for some delay
        tb_test_case = "Test Case 2: Testing badColl";
        $display("\n\n%s", tb_test_case);

        // Snake eats apple #1
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'b1); 
        check_highScore(7'b1); 

        // Snake collides with border
        tb_badColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_badColl = 1'b0;
        check_currentScore(7'b0); 
        check_highScore(7'd2); 

        // ************************************************************************
        // Test Case 3: Test highScore Override
        // ************************************************************************
        tb_test_num += 1;
        reset_dut;
        #(CLK_PERIOD); // allow for some delay
        tb_test_case = "Test Case 3: Test highScore Override";
        $display("\n\n%s", tb_test_case);

        // Snake eats apple #1
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'b1); 
        check_highScore(7'b1); 

        // Snake eats apple #2
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'd2); 
        check_highScore(7'd2); 

        // Snake collides with border and ends game
        tb_badColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_badColl = 1'b0;
        check_currentScore(7'b0); 
        check_highScore(7'd2); 
        
        // Snake eats apple #1
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'b1); 
        check_highScore(7'b1); 

        // Snake eats apple #2
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'd2); 
        check_highScore(7'd2); 

        // Snake eats apple #3
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'd3); 
        check_highScore(7'd3); 

        // Snake eats apple #4
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_currentScore(7'd4); 
        check_highScore(7'd4); 
        $finish; 
    end

endmodule 