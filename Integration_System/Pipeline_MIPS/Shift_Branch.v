module Shift_Branch (
    input  wire [31:0] SignImmD,
    output wire [31:0] SignImmShiftedD
);
     assign SignImmShiftedD = {SignImmD[29:0], 2'b00};

endmodule
