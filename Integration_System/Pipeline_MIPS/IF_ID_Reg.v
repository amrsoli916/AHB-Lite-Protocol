// Module      : IF_ID_Reg
// Description : Pipeline register between IF and ID stages

module IF_ID_Reg (
    input  wire        clk,
    input  wire        reset,

    input  wire        EN,
    input  wire        CLR,

    input  wire [31:0] PCPlus4F,
    input  wire [31:0] InstrF,

    output reg  [31:0] PCPlus4D,
    output reg  [31:0] InstrD
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            PCPlus4D <= 32'b0;
            InstrD   <= 32'h00000000;
        end

        else if (CLR) begin
            PCPlus4D <= 32'b0;
            InstrD   <= 32'h00000000;
        end

        else if (EN) begin
            PCPlus4D <= PCPlus4F;
            InstrD   <= InstrF;
        end

        // EN = 0: hold previous values

    end

endmodule
