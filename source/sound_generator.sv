typedef enum logic {
    OFF = 1'b0,
    ON = 1'b1
} MODE_TYPES;

module sound_generator
#(
    parameter N = 8
)
(
    input logic clk, rst, goodColl_i, badColl_i, button_i,
    input logic [3:0] direction_i,
    output logic [N - 1:0] soundOut
);

    logic goodColl, badColl, toggleMode;
    logic [3:0] newDirection;

    logic [7:0] freq;
    logic playSound;
    MODE_TYPES mode_o;
    logic at_max;
    logic notUsed;

    sound_posedge_detector posDetector1 (.clk(clk), .nRst(~rst), .button_i(notUsed), .button(toggleMode), .goodColl_i(goodColl_i), .badColl_i(badColl_i), .goodColl(goodColl), .badColl(badColl));
    freq_selector_12M freq_12 (.freq(freq), .goodColl_i(goodColl_i), .badColl_i(badColl_i), .direction_i(direction_i));
    sound_fsm fsm1 (.playSound(playSound), .mode_o(mode_o), .clk(clk), .nRst(~rst), .goodColl(goodColl), .badColl(badColl), .button(toggleMode), .direction(newDirection));
    oscillator osc1 (.at_max(at_max), .clk(clk), .nRst(~rst),.goodColl(goodColl), .badColl(badColl));
    dac_counter dac1 (.dacCount(soundOut), .clk(clk), .nRst(~rst), .at_max(at_max));
endmodule