//typedef enum logic {
    //OFF = 1'b0,
    //ON = 1'b1
//} MODE_TYPES;

module oscillator
#(
    parameter N = 8
)
(
    input logic clk, nRst,
    input logic [8:0] freq,
    input MODE_TYPES state,
    input logic playSound,
    output logic at_max
);
logic [N - 1:0] count, count_nxt;
logic at_max_next;
always_ff @(posedge clk, negedge nRst) begin
    if (~nRst) begin
        count <= 0;
        at_max <= 0;
    end else begin
        count <= count_nxt;
        at_max <= at_max_next;
    end
end
always_comb begin
    at_max_next = at_max;
    count_nxt = count;
    if (state == ON && playSound)
        if ({16'b0, count} < 10000000 / (256 * freq)) begin// fix this
            count_nxt = count + 1;
        end else if ({16'b0, count} >= 10000000 / (256 * freq)) begin // fix this
            at_max_next = 1'b1;
        end
    else begin
        count_nxt = 0;
        at_max_next = 1'b0;
    end
end

endmodule