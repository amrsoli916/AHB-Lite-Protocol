module fpu_packer (
    input  wire        Result_Sign, // 1-bit sign from ALU
    input  wire [7:0]  Final_Exp,   // 8-bit normalized exponent
    input  wire [22:0] Final_Mant,  // 23-bit normalized mantissa
    
    output wire [31:0] Final_Result // 32-bit result
);

    assign Final_Result = {Result_Sign, Final_Exp, Final_Mant};

endmodule
