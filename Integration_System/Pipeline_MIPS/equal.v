//=========================================================
// Module : equal
// Description:
// Compares two 32-bit operands.
// Used by BEQ instruction in Decode stage.
//=========================================================

module equal (

    input  wire [31:0] SrcA,
    input  wire [31:0] SrcB,
    output wire Equal

);

    assign Equal = (SrcA == SrcB);

endmodule
