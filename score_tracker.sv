`timescale 1ns / 10ps
module score_tracker(
    input logic clk, nRst, goodColl, badColl,
    output logic [6:0] currScore, highScore,
    output logic isGameComplete
);
    logic [6:0] nextCurrScore, nextHighScore, maxScore;
    assign maxScore = 50;
   
    always_ff @(posedge clk, negedge nRst) begin
        if (~nRst) begin
            currScore <= 7'b0;
            highScore <= 7'b0;
        end else begin
            currScore <= nextCurrScore;
            highScore <= nextHighScore;
        end
    end

    always_comb begin
        nextCurrScore = currScore;
        isGameComplete = 1'b0;
        nextHighScore = highScore;
        if (goodColl) begin
            nextCurrScore = currScore + 1;
            if (nextCurrScore > nextHighScore) begin
                nextHighScore = nextCurrScore;
            end
        end
        if (badColl || currScore >= maxScore) begin
            nextCurrScore = 0;
            isGameComplete = 1'b1;
        end
    end
endmodule