module posedge_detector (
    input logic clk, nRst, goodColl_i, badColl_i, button_i,
    input logic [3:0] direction_i,
    output logic goodColl, badColl, button,
    output logic [3:0] direction
);

logic [6:0] N;
logic [6:0] sig_out;
logic [6:0] posEdge;

always_ff @(posedge clk, negedge nRst) begin
    if (~nRst) begin
        N <= 7'b0;
        sig_out <= 7'b0;
    end else begin
        N <= {goodColl_i, badColl_i, button_i, direction_i};
        sig_out <= N;
    end
end
assign posEdge[6] = N[6] & ~sig_out[6];
assign posEdge[5] = N[5] & ~sig_out[5];
assign posEdge[4] = N[4] & ~sig_out[4];
assign posEdge[3] = N[3] & ~sig_out[3];
assign posEdge[2] = N[2] & ~sig_out[2];
assign posEdge[1] = N[1] & ~sig_out[1];
assign posEdge[0] = N[0] & ~sig_out[0];


assign goodColl = posEdge[6];
assign badColl = posEdge[5];
assign button = posEdge[4];
assign direction = posEdge[3:0];

endmodule