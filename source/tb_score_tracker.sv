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
    logic [6:0] tb_dispScore;
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
    task check_dispScore;
    input logic[6:0] exp_dispScore; 
    begin
        @(negedge tb_clk);
        tb_checking_outputs = 1'b1;
        if(tb_dispScore == exp_dispScore)
            $info("Correct displayed score: %0d.", exp_dispScore);
        else
            $error("Incorrect displayed score. Expected: %0d. Actual: %0d.", exp_dispScore, tb_dispScore); 
        
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
                .dispScore(tb_dispScore),
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
        check_dispScore('0);
   

        // Check that the reset value is maintained during a clock cycle
        @(negedge tb_clk);
        check_dispScore('0);
        


        // ************************************************************************
        // Test Case 1: Updating displayScore
        // ************************************************************************
        tb_test_num += 1;
        reset_dut;
        #(CLK_PERIOD); // allow for some delay
        tb_test_case = "Test Case 1: Updating currentScore and highScore";
        $display("\n\n%s", tb_test_case);


        for (integer i = 0; i < 100; i++) begin
            // Snake eats apple #i
            tb_goodColl = 1'b1;
            #(CLK_PERIOD); // allow for some delay
            tb_goodColl = 1'b0;
            
        end
        
        


      
 
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
        check_dispScore(7'b1); 
        

        // Snake collides with border
        tb_badColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_badColl = 1'b0;
        
        check_dispScore(7'd1); 

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
        check_dispScore(7'b1); 
        

        // Snake eats apple #2
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_dispScore(7'd2); 
        

        // Snake collides with border and ends game
        tb_badColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_badColl = 1'b0;
        
        check_dispScore(7'd2); 
        
        // Snake eats apple #1
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_dispScore(7'b1); 
        

        // Snake eats apple #2
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_dispScore(7'd2); 
       

        // Snake eats apple #3
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_dispScore(7'd3); 
        

        // Snake eats apple #4
        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_goodColl = 1'b0;
        check_dispScore(7'd4); 
       
        // Snake collides with border and ends game
        tb_badColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        tb_badColl = 1'b0;

        #(CLK_PERIOD * 5); // making sure the high score stays there
        check_dispScore(7'd4);
        $finish; 
    end

endmodule 