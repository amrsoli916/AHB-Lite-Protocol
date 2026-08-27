// Module      : EX_MEM_Reg
// Description : Pipeline register between EX and MEM stages
//
// ControlE[2] = RegWriteE
// ControlE[1] = MemtoRegE
// ControlE[0] = MemWriteE

module EX_MEM_Reg (

    input  wire        clk,
    input  wire        reset,
    input  wire        En,

    input  wire [2:0]  ControlE,

    input  wire        FpuRegE,
    input  wire        MemSizeE,

    input  wire [31:0] ALUOutE,
    input  wire [31:0] WriteDataE,
    input  wire [4:0]  WriteRegE,

    input  wire [31:0] FPUOutE,
    input  wire [4:0]  FRdE,

    output reg  [2:0]  ControlM,
    output reg         FpuRegM,
    output reg         MemSizeM,

    output reg  [31:0] ALUOutM,
    output reg  [31:0] WriteDataM,
    output reg  [4:0]  WriteRegM,

    output reg  [31:0] FPUOutM,
    output reg  [4:0]  FRdM
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            ControlM   <= 3'b000;
            FpuRegM    <= 1'b0;
            MemSizeM   <= 1'b0;

            ALUOutM    <= 32'b0;
            WriteDataM <= 32'b0;
            WriteRegM  <= 5'b0;

            FPUOutM    <= 32'b0;
            FRdM       <= 5'b0;

        end

        else if(En)begin

            ControlM   <= ControlE;
            FpuRegM    <= FpuRegE;
            MemSizeM   <= MemSizeE;

            ALUOutM    <= ALUOutE;
            WriteDataM <= WriteDataE;
            WriteRegM  <= WriteRegE;

            FPUOutM    <= FPUOutE;
            FRdM       <= FRdE;

        end

    end

endmodule
