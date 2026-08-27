// Module      : MEM_WB_Reg
// Description : Pipeline register between MEM and WB stages
//
// ControlM[1] = RegWriteM
// ControlM[0] = MemtoRegM

// ControlW[1] = RegWriteW
// ControlW[0] = MemtoRegW

module MEM_WB_Reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        En,

    // Integer control signals
    input  wire [1:0]  ControlM,

    // Floating-point write enable
    input  wire        FpuRegM,

    // Integer datapath
    input  wire [31:0] ReadDataM,
    input  wire [31:0] ALUOutM,
    input  wire [4:0]  WriteRegM,

    // Floating-point datapath
    input  wire [31:0] FPUOutM,
    input  wire [4:0]  FRdM,

    // WB-stage outputs
    output reg  [1:0]  ControlW,
    output reg         FpuRegW,

    output reg  [31:0] ReadDataW,
    output reg  [31:0] ALUOutW,
    output reg  [4:0]  WriteRegW,

    output reg  [31:0] FPUOutW,
    output reg  [4:0]  FRdW
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Disable all architectural writes
            ControlW  <= 2'b00;
            FpuRegW   <= 1'b0;

            // Clear integer WB data
            ReadDataW <= 32'b0;
            ALUOutW   <= 32'b0;
            WriteRegW <= 5'b0;

            // Clear floating-point WB data
            FPUOutW   <= 32'b0;
            FRdW      <= 5'b0;
        end
        else if(En) begin
            // Transfer MEM-stage values into WB stage
            ControlW  <= ControlM;
            FpuRegW   <= FpuRegM;

            ReadDataW <= ReadDataM;
            ALUOutW   <= ALUOutM;
            WriteRegW <= WriteRegM;

            FPUOutW   <= FPUOutM;
            FRdW      <= FRdM;
        end
    end

endmodule
