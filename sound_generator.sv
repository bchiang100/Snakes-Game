typedef enum logic {
    OFF = 1'b0,
    ON = 1'b1
} MODE_TYPES;

module sound_fsm(
    input logic clk, nRst, goodColl, badColl, button,
    input logic [3:0] direction,
    output logic playSound,
    output MODE_TYPES mode_o // current state
);
MODE_TYPES next_state;

always_ff @(posedge clk, negedge nRst) begin
    if (~nRst) begin
        mode_o <= ON;
    end else begin
        mode_o <= next_state;
    end
end

always_comb begin
    playSound = 1'b0;
    next_state = mode_o;
    case (mode_o)
        ON:
            if (button) begin
                next_state = OFF;
            end
            else if (goodColl || badColl || |direction) begin
                playSound = 1'b1;
            end
        OFF:
            if (button) begin
                next_state = ON;
            end
    endcase
end

endmodule