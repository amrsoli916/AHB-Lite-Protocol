// Module      : Hazard_Unit
// Description : Hazard handling for a 5-stage pipelined MIPS
//               with a single-cycle FPU supporting add.s and sub.s

module Hazard_Unit (

    // Decode-stage opcode
    input  wire [5:0] OpD,

    // Integer register numbers
    input  wire [4:0] RsD,
    input  wire [4:0] RtD,

    input  wire [4:0] RsE,
    input  wire [4:0] RtE,

    input  wire [4:0] WriteRegE,
    input  wire [4:0] WriteRegM,
    input  wire [4:0] WriteRegW,

    // Integer control signals
    input  wire       RegWriteE,
    input  wire       RegWriteM,
    input  wire       RegWriteW,

    input  wire       MemtoRegE,
    input  wire       MemtoRegM,

    input  wire       BranchD,

    // Floating-point register numbers
    input  wire [4:0] FRsD,
    input  wire [4:0] FRtD,

    input  wire [4:0] FRsE,
    input  wire [4:0] FRtE,

    input  wire [4:0] FRdM,
    input  wire [4:0] FRdW,

    // Floating-point control signals
    input  wire       FpuRegD,
    input  wire       FpuRegE,
    input  wire       FpuRegM,
    input  wire       FpuRegW,

    // Integer Decode-stage forwarding
    output wire       ForwardAD,
    output wire       ForwardBD,

    // Integer Execute-stage forwarding
    output reg  [1:0] ForwardAE,
    output reg  [1:0] ForwardBE,

    // FPU Execute-stage forwarding
    output reg  [1:0] FForwardAE,
    output reg  [1:0] FForwardBE,

    // FPU Writeback-to-Decode bypass
    output wire       FForwardSrcA,
    output wire       FForwardSrcB,

    // Pipeline stall and flush
    output wire       StallF,
    output wire       StallD,
    output wire       FlushE
);

    localparam [1:0] FWD_REG = 2'b00;
    localparam [1:0] FWD_WB  = 2'b01;
    localparam [1:0] FWD_MEM = 2'b10;

    localparam [5:0] OP_RTYPE = 6'b000000;
    localparam [5:0] OP_LW    = 6'b100011;
    localparam [5:0] OP_SW    = 6'b101011;
    localparam [5:0] OP_BEQ   = 6'b000100;
    localparam [5:0] OP_ADDI  = 6'b001000;

    wire UsesRsD;
    wire UsesRtD;

    wire LoadUseStall;
    wire BranchStall;

    // Instructions that use Rs as an integer source
    assign UsesRsD =
        (OpD == OP_RTYPE) ||
        (OpD == OP_LW)    ||
        (OpD == OP_SW)    ||
        (OpD == OP_BEQ)   ||
        (OpD == OP_ADDI);

    // Instructions that use Rt as an integer source
    assign UsesRtD =
        (OpD == OP_RTYPE) ||
        (OpD == OP_SW)    ||
        (OpD == OP_BEQ);

    // Forward an ALU result from MEM to the branch comparator
    // A load is excluded because ALUOutM contains its address
    assign ForwardAD =
        BranchD                   &&
        RegWriteM                 &&
        !MemtoRegM                &&
        (WriteRegM != 5'd0)       &&
        (RsD == WriteRegM);

    assign ForwardBD =
        BranchD                   &&
        RegWriteM                 &&
        !MemtoRegM                &&
        (WriteRegM != 5'd0)       &&
        (RtD == WriteRegM);

    // Integer forwarding into the Execute-stage ALU
    always @(*) begin

        ForwardAE = FWD_REG;
        ForwardBE = FWD_REG;

        // Operand A: MEM has priority over WB
        if (
            RegWriteM             &&
            !MemtoRegM            &&
            (WriteRegM != 5'd0)   &&
            (RsE == WriteRegM)
        )
            ForwardAE = FWD_MEM;

        else if (
            RegWriteW             &&
            (WriteRegW != 5'd0)   &&
            (RsE == WriteRegW))
            ForwardAE = FWD_WB;

        // Operand B: MEM has priority over WB
        if (
            RegWriteM             &&
            !MemtoRegM            &&
            (WriteRegM != 5'd0)   &&
            (RtE == WriteRegM))
            ForwardBE = FWD_MEM;

        else if (
            RegWriteW             &&
            (WriteRegW != 5'd0)   &&
            (RtE == WriteRegW))
            ForwardBE = FWD_WB;

    end

    // Stall one cycle when an instruction needs a value
    // currently being loaded by lw in the Execute stage
    assign LoadUseStall =
        MemtoRegE                &&
        RegWriteE                &&
        (WriteRegE != 5'd0)      &&
        (
            (UsesRsD && (RsD == WriteRegE)) ||
            (UsesRtD && (RtD == WriteRegE)));

    // Branch operands are required in Decode
    // Stall if the required result is still in Execute
    // or if it is a load result still in Memory
    assign BranchStall =
        BranchD &&
        ((
                RegWriteE                 &&
                (WriteRegE != 5'd0)       &&
                (
                    (RsD == WriteRegE) ||
                    (RtD == WriteRegE)))||
		(
                MemtoRegM                 &&
                RegWriteM                 &&
                (WriteRegM != 5'd0)       &&
                ((RsD == WriteRegM) ||(RtD == WriteRegM))));

    assign StallF = LoadUseStall | BranchStall;
    assign StallD = LoadUseStall | BranchStall;
    assign FlushE = LoadUseStall | BranchStall;

    // FPU forwarding into Execute stage
    // $f0 is not excluded because it is a normal writable FPU register
    always @(*) begin

        FForwardAE = FWD_REG;
        FForwardBE = FWD_REG;

        if (FpuRegE) begin

            // Floating operand A
            if (FpuRegM &&(FRsE == FRdM))
                FForwardAE = FWD_MEM;

            else if (FpuRegW &&(FRsE == FRdW))
                FForwardAE = FWD_WB;

            // Floating operand B
            if (FpuRegM &&(FRtE == FRdM))
                FForwardBE = FWD_MEM;
            else if (FpuRegW &&(FRtE == FRdW))FForwardBE = FWD_WB;
        end
    end
    // Same-cycle WB-to-Decode bypass for the Floating Register File
    assign FForwardSrcA =
        FpuRegD &&
        FpuRegW &&
        (FRsD == FRdW);

    assign FForwardSrcB =
        FpuRegD &&
        FpuRegW &&
        (FRtD == FRdW);

endmodule
