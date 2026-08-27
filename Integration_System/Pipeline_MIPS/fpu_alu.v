module fpu_alu (
    input  wire [23:0] Aligned_Mant_A,
    input  wire [23:0] Aligned_Mant_B,
    input  wire        Sign_A,
    input  wire        Sign_B,
    input  wire        Op_Sub,

    output reg  [24:0] Result_Mant,
    output reg         Result_Sign
);

    wire Eff_Sign_B;
    wire Eff_Op;

    assign Eff_Sign_B = Sign_B ^ Op_Sub;
    assign Eff_Op     = Sign_A ^ Eff_Sign_B;

    reg [24:0] next_Result_Mant;
    reg        next_Result_Sign;

    always @(*) begin

        next_Result_Mant = 25'd0;
        next_Result_Sign = 1'b0;

        if (Eff_Op == 1'b0) begin
            next_Result_Mant = {1'b0, Aligned_Mant_A} + {1'b0, Aligned_Mant_B};
            next_Result_Sign = Sign_A;
        end
        else begin
            if (Aligned_Mant_A >= Aligned_Mant_B) begin
                next_Result_Mant = {1'b0, Aligned_Mant_A} - {1'b0, Aligned_Mant_B};
                next_Result_Sign = Sign_A;
            end
            else begin
                next_Result_Mant = {1'b0, Aligned_Mant_B} - {1'b0, Aligned_Mant_A};
                next_Result_Sign = Eff_Sign_B;
            end
        end

        Result_Mant = next_Result_Mant;
        
        if (next_Result_Mant == 25'd0)
            Result_Sign = 1'b0;
        else
            Result_Sign = next_Result_Sign;

    end

endmodule
