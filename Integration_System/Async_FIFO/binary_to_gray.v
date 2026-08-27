module binary_to_gray #(parameter ADDRESS_WIDTH=7) (binary,gray);
    input [ADDRESS_WIDTH:0] binary;
    output [ADDRESS_WIDTH:0] gray;

    assign gray = binary ^ (binary >> 1); //gray = binary ^{0,binary[ADDRESS_WIDTH:1]}
                                          //where binay[ADDRESS_WIDTH] ^ 0 = binay[ADDRESS_WIDTH]
                                          //gray = {binay[ADDRESS_WIDTH], binary[i]^binary[i-1]}
endmodule