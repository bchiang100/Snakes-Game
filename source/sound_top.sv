`default_nettype none
typedef enum logic {
    OFF = 1'b0,
    ON = 1'b1
} MODE_TYPES;
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
    logic clk, rst;
    logic goodColl_i, badColl_i, toggleMode_i;
    logic goodColl, badColl, toggleMode;

    logic [3:0] direction_i;
    logic [3:0] newDirection;

    logic [7:0] freq;
    logic playSound;
    MODE_TYPES mode_o;
    logic at_max;
    logic [7:0] soundOut;

    assign clk = hz100;
    assign rst = reset;
    assign direction_i = {pb[13], pb[5], pb[8], pb[10]};
    assign goodColl_i = pb[0];
    assign badColl_i = pb[1];
    assign toggleMode_i = pb[2];
    assign soundOut = {right[7], right[6], right[5], right[4], right[3], right[2], right[1], right[0]};

    sound_posedge_detector posDetector1 (.clk(clk), .nRst(~rst), .goodColl_i(goodColl_i), .badColl_i(badColl_i), .goodColl(goodColl), .badColl(badColl));
    oscillator osc1 (.at_max(at_max), .clk(clk), .nRst(~rst), .state(mode_o), .goodColl(goodColl), .badColl(badColl));
    dac_counter dac1 (.dacCount(soundOut), .clk(clk), .nRst(~rst), .at_max(at_max));

endmodule

module dac_counter 
#(
    parameter N = 8
)
(
    input logic clk, nRst, at_max,
    output logic [N - 1:0] dacCount
);

logic [N - 1:0] dacCount_nxt;
always_ff @(posedge clk, negedge nRst) begin
    if (~nRst) begin
        dacCount <= 0;
    end else begin
        dacCount <= dacCount_nxt;
    end
end

always_comb begin
    if (at_max)
        dacCount_nxt = dacCount + 1;
    else
        dacCount_nxt = dacCount;
end

endmodule

module sound_posedge_detector (
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
assign posEdge = N & ~sig_out | (N & sig_out);

assign goodColl = N[1] & ~sig_out[1] | (N[1] & sig_out[1]);
assign badColl = N[0] & ~sig_out[0] | (N[0] & sig_out[0]);

endmodule


module oscillator
#(
    parameter N = 8
)
(
    input logic clk, nRst,
    input MODE_TYPES state,
    input logic goodColl, badColl,
    output logic at_max
);
logic [23:0] timer, timer_nxt;
logic [7:0] freq, freq_nxt;
logic [N - 1:0] count, count_nxt;
logic [23:0] stayCount, stayCount_nxt;
logic at_max_nxt, keepCounting, keepCounting_nxt;

always_ff @(posedge clk, negedge nRst) begin
    if (~nRst) begin
        count <= 0;
        at_max <= 0;
        stayCount <= 0;
        keepCounting <= 0;
        freq <= 0;
        timer <= 0;
    end else begin
        count <= count_nxt;
        at_max <= at_max_nxt;
        stayCount <= stayCount_nxt;
        keepCounting <= keepCounting_nxt;
        freq <= freq_nxt;
        timer <= timer_nxt;
    end
end

always_comb begin
    at_max_nxt = at_max;
    count_nxt = count;
    keepCounting_nxt = keepCounting;
    stayCount_nxt = stayCount;
    timer_nxt = timer;
    freq_nxt = freq;
    // 12Mhz is for FPGA, 10Mhz is for final chip
    if (goodColl && ~keepCounting) begin
        freq_nxt = 8'd89; // 12M / 1/((1/440) / 256) - (SWITCH OUT TO 89 FOR FINAL)
        timer_nxt = 3000000;
    end
    if (badColl && ~keepCounting) begin
        freq_nxt = 8'd156; // 12M / 1/((1/250) / 256) - (SWITCH OUT TO 156 FOR FINAL)
        timer_nxt = 10000000;
    end

    if (at_max == 1'b1) begin
        at_max_nxt = 1'b0;
    end
    if (goodColl || badColl) begin
        keepCounting_nxt = 1'b1;
    end
    if (keepCounting_nxt) begin
        if (stayCount < timer) begin
            if (count < freq_nxt) begin
                count_nxt = count + 1;
            end else if (count >= freq_nxt) begin 
                at_max_nxt = 1'b1;
                count_nxt = 0;
            end
            stayCount_nxt = stayCount + 1;
        end else begin
            keepCounting_nxt = 1'b0;
            stayCount_nxt = 0;
        end
    end else if (~keepCounting_nxt) begin
        count_nxt = count;
        at_max_nxt = at_max;
    end
end

endmodule
