/*
    Module Name: tb_sound_fsm.sv
    Description: Test bench for sound finite state machine
*/

`timescale 1ns / 10ps

module tb_sound_generator ();

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
    logic tb_goodColl, tb_badColl, tb_button;
    logic [3:0] tb_direction;
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
    
    // Task that presses the button once
    task single_button_press;
    begin
        @(negedge tb_clk);
        tb_button = 1'b1; 
        @(negedge tb_clk);
        tb_button = 1'b0; 
        @(posedge tb_clk);  // Task ends in rising edge of clock: remember this!
    end
    endtask

    // Task to check mode output
    // task check_mode_o;
    // input logic expected_mode; 
    // input string string_mode; 
    // begin
    //     @(negedge tb_clk); 
    //     tb_checking_outputs = 1'b1; 
    //     if(tb_mode_o == expected_mode)
    //         $info("Correct Mode: %s.", string_mode);
    //     else
    //         $error("Incorrect mode. Expected: %s. Actual: %s.", string_mode, tb_mode_o); 
        
    //     #(1);
        
    // end
    // endtask

    // Task to check sound toggle output
    task check_dacCount;
    input logic exp_dacCount; 
    begin
        @(negedge tb_clk);
        tb_checking_outputs = 1'b1;
        if(tb_dacCount== exp_dacCount)
            $info("Correct playSound: %0d.", exp_dacCount);
        else
            $error("Incorrect mode. Expected: %0d. Actual: %0d.", exp_dacCount, tb_dacCount); 
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
    sound_generator DUT(.clk(tb_clk),
                .nRst(tb_nRst_i),
                .button_i(tb_button),
                .goodColl_i(tb_goodColl),
                .badColl_i(tb_badColl),
                .direction_i(tb_direction),
                .dacCount(tb_dacCount));
                

    // Main Test Bench Process
    initial begin
        // Signal dump
        $dumpfile("dump.vcd");
        $dumpvars; 

        // Initialize test bench signals
        tb_button = 1'b0; 
        tb_nRst_i = 1'b1;
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
        
        check_dacCount('0);

        // Check that the reset value is maintained during a clock cycle
        @(negedge tb_clk);
        check_dacCount('0);

        // Release the reset away from a clock edge
        @(negedge tb_clk);
        tb_nRst_i  = 1'b1;   // Deactivate the chip reset
        // Check that internal state was correctly keep after reset release
        check_dacCount('0);


        // ************************************************************************
        // Test Case 1: Test playSound
        // ************************************************************************
        tb_test_num += 1;
        tb_test_case = "Test Case 1: Test playSound";
        $display("\n\n%s", tb_test_case);

        tb_goodColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        //check_playSound(1'b1);
        tb_goodColl = 1'b0;

        #(CLK_PERIOD * 300);

        tb_badColl = 1'b1;
        #(CLK_PERIOD); // allow for some delay
        //check_playSound(1'b1);
        tb_badColl = 1'b0;

        #(CLK_PERIOD * 300);

        tb_direction = 4'b0001;
        #(CLK_PERIOD); // allow for some delay
        //check_playSound(1'b1);
        tb_direction = 4'b0000;


        #(CLK_PERIOD * 300);
        #(CLK_PERIOD); // allow for some delay
        //check_playSound(1'b0);

        // ************************************************************************
        // Test Case 2: Test Toggle ON/OFF
        // ************************************************************************
        // tb_test_num += 1;
        // tb_test_case = "Test Case 1: Test Toggle ON/OFF";
        // $display("\n\n%s", tb_test_case);

        // single_button_press();
        // check_mode_o(OFF, "OFF");

        // tb_goodColl = 1'b1;
        // #(CLK_PERIOD); // allow for some delay
        // check_playSound(1'b0);
        // tb_goodColl = 1'b0;

        // tb_badColl = 1'b1;
        // #(CLK_PERIOD); // allow for some delay
        // check_playSound(1'b0);
        // tb_badColl = 1'b0;

        // tb_direction = 4'b0001;
        // #(CLK_PERIOD); // allow for some delay
        // check_playSound(1'b0);
        // tb_direction = 4'b0000;

        // #(CLK_PERIOD);
        // single_button_press();
        // check_mode_o(ON, "ON");
        $finish; 
    end

endmodule 