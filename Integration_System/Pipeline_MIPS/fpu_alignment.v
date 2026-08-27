`timescale 1ns / 1ps

module fpu_alignment (
    input  wire [7:0]  Exp_A,
    input  wire [7:0]  Exp_B,
    input  wire [23:0] Mant_A,
    input  wire [23:0] Mant_B,

    output reg  [7:0]  Common_Exp,
    output reg  [23:0] Aligned_Mant_A,
    output reg  [23:0] Aligned_Mant_B
);

    reg [7:0] diff;

    always @(*) begin
        if (Exp_A > Exp_B) begin
            diff = Exp_A - Exp_B;
            Common_Exp = Exp_A;
            Aligned_Mant_A = Mant_A;
            Aligned_Mant_B = Mant_B >> diff;
        end 
        else begin
            diff = Exp_B - Exp_A;
            Common_Exp = Exp_B;
            Aligned_Mant_A = Mant_A >> diff;
            Aligned_Mant_B = Mant_B;
        end
    end

endmodule
