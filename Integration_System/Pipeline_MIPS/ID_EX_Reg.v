// Module      : ID_EX_Reg
// Description : Pipeline register between ID and EX stages
//
// ControlD[4] = RegWriteD
// ControlD[3] = MemtoRegD
// ControlD[2] = MemWriteD
// ControlD[1] = ALUSrcD
// ControlD[0] = RegDstD

module ID_EX_Reg (

    input  wire        clk,
    input  wire        reset,
    input  wire        CLR,
    input  wire        EN,

    input  wire [4:0]  ControlD,
    input  wire [2:0]  ALUControlD,

    input  wire        FpuRegD,
    input  wire        FpuConD,
    input  wire        MemSizeD,

    input  wire [31:0] RD1D,
    input  wire [31:0] RD2D,
    input  wire [31:0] SignImmD,

    input  wire [4:0]  RsD,
    input  wire [4:0]  RtD,
    input  wire [4:0]  RdD,

    input  wire [31:0] FRD1D,
    input  wire [31:0] FRD2D,

    input  wire [4:0]  FRsD,
    input  wire [4:0]  FRtD,
    input  wire [4:0]  FRdD,

    output reg  [4:0]  ControlE,
    output reg  [2:0]  ALUControlE,

    output reg         FpuRegE,
    output reg         FpuConE,
    output reg         MemSizeE,

    output reg  [31:0] RD1E,
    output reg  [31:0] RD2E,
    output reg  [31:0] SignImmE,

    output reg  [4:0]  RsE,
    output reg  [4:0]  RtE,
    output reg  [4:0]  RdE,

    output reg  [31:0] FRD1E,
    output reg  [31:0] FRD2E,

    output reg  [4:0]  FRsE,
    output reg  [4:0]  FRtE,
    output reg  [4:0]  FRdE
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            ControlE    <= 5'b00000;
            ALUControlE <= 3'b000;

            FpuRegE     <= 1'b0;
            FpuConE     <= 1'b0;
            MemSizeE    <= 1'b0;

            RD1E        <= 32'b0;
            RD2E        <= 32'b0;
            SignImmE    <= 32'b0;

            RsE         <= 5'b0;
            RtE         <= 5'b0;
            RdE         <= 5'b0;

            FRD1E       <= 32'b0;
            FRD2E       <= 32'b0;

            FRsE        <= 5'b0;
            FRtE        <= 5'b0;
            FRdE        <= 5'b0;

        end

        else if (CLR) begin

            // Insert a bubble into the Execute stage
            ControlE    <= 5'b00000;
            ALUControlE <= 3'b000;

            FpuRegE     <= 1'b0;
            FpuConE     <= 1'b0;
            MemSizeE    <= 1'b0;

            RD1E        <= 32'b0;
            RD2E        <= 32'b0;
            SignImmE    <= 32'b0;

            RsE         <= 5'b0;
            RtE         <= 5'b0;
            RdE         <= 5'b0;

            FRD1E       <= 32'b0;
            FRD2E       <= 32'b0;

            FRsE        <= 5'b0;
            FRtE        <= 5'b0;
            FRdE        <= 5'b0;

        end

        else if(EN)begin

            ControlE    <= ControlD;
            ALUControlE <= ALUControlD;

            FpuRegE     <= FpuRegD;
            FpuConE     <= FpuConD;
            MemSizeE    <= MemSizeD;

            RD1E        <= RD1D;
            RD2E        <= RD2D;
            SignImmE    <= SignImmD;

            RsE         <= RsD;
            RtE         <= RtD;
            RdE         <= RdD;

            FRD1E       <= FRD1D;
            FRD2E       <= FRD2D;

            FRsE        <= FRsD;
            FRtE        <= FRtD;
            FRdE        <= FRdD;

        end

    end

endmodule
