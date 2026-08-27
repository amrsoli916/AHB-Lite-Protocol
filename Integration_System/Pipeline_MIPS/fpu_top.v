
module fpu_top (
    input  wire [31:0] A,          
    input  wire [31:0] B,           
    input  wire        Op_Sub,      // 0 for Addition, 1 for Subtraction
    
    output wire [31:0] Final_Result // 32-bit floating point result
);

   
    // Wires from Unpacker
    wire        sign_a, sign_b;
    wire [7:0]  exp_a, exp_b;
    wire [23:0] mant_a, mant_b;     // 24 bits (23 fraction + 1 hidden bit)

    // Wires from Alignment
    wire [7:0]  common_exp;
    wire [23:0] aligned_mant_a;
    wire [23:0] aligned_mant_b;

    // Wires from ALU
    wire        result_sign;
    wire [24:0] alu_mant;           // 25 bits (to catch overflow/carry)

    // Wires from Normalizer
    wire [7:0]  final_exp;
    wire [22:0] final_mant;         // 23 bits (hidden bit removed)


    // 2. Module Instantiations (The Datapath)

    // Stage 1: Extract Sign, Exponent, and add the Hidden Bit
    fpu_unpacker stage1_unpack (
        .A(A), 
        .B(B),
        .Sign_A(sign_a), 
        .Sign_B(sign_b),
        .Exp_A(exp_a), 
        .Exp_B(exp_b),
        .Mant_A(mant_a), 
        .Mant_B(mant_b)
    );

    // Stage 2: Compare Exponents and Shift the smaller mantissa
    fpu_alignment stage2_align (
        .Exp_A(exp_a), 
        .Exp_B(exp_b),
        .Mant_A(mant_a), 
        .Mant_B(mant_b),
        .Aligned_Mant_A(aligned_mant_a),
        .Aligned_Mant_B(aligned_mant_b),
        .Common_Exp(common_exp)
    );

    // Stage 3: Perform Addition or Subtraction on the Mantissas
    fpu_alu stage3_alu (
        .Op_Sub(Op_Sub),
        .Sign_A(sign_a),
        .Sign_B(sign_b),
        .Aligned_Mant_A(aligned_mant_a),
        .Aligned_Mant_B(aligned_mant_b),
        .Result_Sign(result_sign),
        .Result_Mant(alu_mant)
    );

    // Stage 4: Normalize the result (Handle Overflow & Underflow)
    fpu_normalizer stage4_norm (
        .ALU_Mant(alu_mant),
        .Common_Exp(common_exp),
        .Final_Mant(final_mant),
        .Final_Exp(final_exp)
    );

    // Stage 5: Pack the components back into a 32-bit 
    fpu_packer stage5_pack (
        .Result_Sign(result_sign),
        .Final_Exp(final_exp),
        .Final_Mant(final_mant),
        .Final_Result(Final_Result)
    );

endmodule