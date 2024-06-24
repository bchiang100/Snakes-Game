module freq_selector(
    input logic goodColl_i, badColl_i, 
    input logic [3:0] direction_i,
    output logic [8:0] freq
);

always_comb begin
    freq = 0;
    if (goodColl_i)
        freq = 9'd440; // A
    if (badColl_i)
        freq = 9'd311; // D Sharp
    if (|direction_i)
        freq = 9'd262; // C
end

endmodule