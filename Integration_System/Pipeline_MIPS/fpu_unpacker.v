module fpu_unpacker (
    input  wire [31:0] A,         
    input  wire [31:0] B,         
    
    output wire        Sign_A,    
    output wire        Sign_B,  
    output wire [7:0]  Exp_A,    
    output wire [7:0]  Exp_B,    
    output wire [23:0] Mant_A,    
    output wire [23:0] Mant_B    
);

    // sign bit 
    assign Sign_A = A[31];
    assign Sign_B = B[31];

    // exponent 
    assign Exp_A  = A[30:23];
    assign Exp_B  = B[30:23];

    // Hidden Bit
    wire hidden_bit_A;
    wire hidden_bit_B;
    
    assign hidden_bit_A = (Exp_A == 8'd0) ? 1'b0 : 1'b1;
    assign hidden_bit_B = (Exp_B == 8'd0) ? 1'b0 : 1'b1;

    // Mantissa
    assign Mant_A = {hidden_bit_A, A[22:0]};
    assign Mant_B = {hidden_bit_B, B[22:0]};

endmodule
