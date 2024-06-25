// FOR SCORE TRACKER THINK ABOUT MAKING CURR SCORE STAY THERE FOR A FEW SECS LONGER WHILE FLASHING SO USER CAN SEE SCORE ACHIEVE BEFORE HIGH SCORE UPDATES BACK
module score_tracker(
    input logic clk, nRst, goodColl, badColl,
    output logic [6:0] dispScore,
    output logic isGameComplete
);
    logic [6:0] nextCurrScore, nextHighScore, maxScore;
    logic [6:0] currScore, highScore, nextDispScore;
    logic isGameComplete_nxt;

    assign maxScore = 50;
   
    always_ff @(posedge clk, negedge nRst) begin
        if (~nRst) begin
            currScore <= 7'b0;
            highScore <= 7'b0;
            dispScore <= 7'b0;
            isGameComplete <= 1'b0;
        end else begin
            currScore <= nextCurrScore;
            highScore <= nextHighScore;
            isGameComplete <= isGameComplete_nxt;
            dispScore <= nextDispScore;
        end
    end

    always_comb begin
        nextCurrScore = currScore;
        isGameComplete_nxt = isGameComplete;
        nextHighScore = highScore;
        if (goodColl) begin
            isGameComplete_nxt = 1'b0;
            nextCurrScore = currScore + 1;
            if (nextCurrScore > nextHighScore) begin
                nextHighScore = nextCurrScore;
            end
        end
        if (badColl || currScore >= maxScore) begin
            nextCurrScore = 0;
            isGameComplete_nxt = 1'b1;
        end
        if (!isGameComplete_nxt) begin
                nextDispScore = nextCurrScore;
            end else begin
                nextDispScore = nextHighScore;
            end
    end
endmodule
