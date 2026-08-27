// Module      : TOP_Pip_MIPS
// Description : 5-stage pipelined MIPS processor
//               with single-cycle floating-point add.s and sub.s

module TOP_Pip_MIPS (
    input  wire       clk,
    input  wire       reset, 

    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire        mem_write_en,
    output wire        mem_read_en,
    output wire        output_size,

    input wire  [31:0] mem_read_data,
    input wire         CPU_Command_Ready,
    input wire         Read_Valid
);

    // ============================================================
    // Fetch Stage
    // ============================================================

    wire [31:0] PCF;
    wire [31:0] PCNextF;
    wire [31:0] PCPlus4F;
    wire [31:0] InstrF;

    // ============================================================
    // Decode Stage
    // ============================================================

    wire [31:0] PCPlus4D;
    wire [31:0] InstrD;

    wire [5:0]  OpD;
    wire [4:0]  FmtD;
    wire [5:0]  FunctD;

    wire [4:0]  RsD;
    wire [4:0]  RtD;
    wire [4:0]  RdD;

    wire [4:0]  FRsD;
    wire [4:0]  FRtD;
    wire [4:0]  FRdD;

    wire [31:0] RD1D;
    wire [31:0] RD2D;

    wire [31:0] RawFRD1D;
    wire [31:0] RawFRD2D;

    wire [31:0] FRD1D;
    wire [31:0] FRD2D;

    wire [31:0] SignImmD;
    wire [31:0] SignImmShiftedD;
    wire [31:0] PCBranchD;

    wire [31:0] BranchSrcAD;
    wire [31:0] BranchSrcBD;

    wire EqualD;
    wire PCSrcD;
    wire MemSizeD;

    // Decode control signals
    wire       MemtoRegD;
    wire       MemWriteD;
    wire       BranchD;
    wire [2:0] ALUControlD;
    wire       ALUSrcD;
    wire       RegDstD;
    wire       RegWriteD;

    wire       FpuRegD;
    wire       FpuConD;

    wire [4:0] ControlD;

    // ============================================================
    // Execute Stage
    // ============================================================

    wire [4:0] ControlE;
    wire [2:0] ALUControlE;

    wire       RegWriteE;
    wire       MemtoRegE;
    wire       MemWriteE;
    wire       ALUSrcE;
    wire       RegDstE;
    wire       MemSizeE;

    wire       FpuRegE;
    wire       FpuConE;


    wire [31:0] RD1E;
    wire [31:0] RD2E;
    wire [31:0] SignImmE;

    wire [4:0] RsE;
    wire [4:0] RtE;
    wire [4:0] RdE;

    wire [31:0] FRD1E;
    wire [31:0] FRD2E;

    wire [4:0] FRsE;
    wire [4:0] FRtE;
    wire [4:0] FRdE;

    wire [1:0] ForwardAE;
    wire [1:0] ForwardBE;

    wire [31:0] SrcAE;
    wire [31:0] ForwardedBE;
    wire [31:0] SrcBE;

    wire [31:0] WriteDataE;
    wire [4:0]  WriteRegE;

    wire [31:0] ALUOutE;

    wire [1:0] FForwardAE;
    wire [1:0] FForwardBE;

    wire [31:0] FPUOperandA;
    wire [31:0] FPUOperandB;
    wire [31:0] FPUOutE;

    // ============================================================
    // Memory Stage
    // ============================================================

    wire [2:0] ControlM;

    wire       RegWriteM;
    wire       MemtoRegM;
    wire       MemWriteM;
    wire       MemSizeM;

    wire       FpuRegM;

    wire [31:0] ALUOutM;
    wire [31:0] WriteDataM;
    wire [4:0]  WriteRegM;

    wire [31:0] ReadDataM;

    wire [31:0] FPUOutM;
    wire [4:0]  FRdM;

    // ============================================================
    // Writeback Stage
    // ============================================================

    wire [1:0] ControlW;

    wire       RegWriteW;
    wire       MemtoRegW;

    wire       FpuRegW;

    wire [31:0] ReadDataW;
    wire [31:0] ALUOutW;
    wire [4:0]  WriteRegW;

    wire [31:0] ResultW;

    wire [31:0] FPUOutW;
    wire [4:0]  FRdW;

    // ============================================================
    // Hazard Signals
    // ============================================================

    wire ForwardAD;
    wire ForwardBD;

    wire FForwardSrcA;
    wire FForwardSrcB;

    wire StallF;
    wire StallD;
    wire FlushE;

    wire CPU_Stall;
    wire Pipeline_EN;

    assign CPU_Stall = (mem_write_en && !CPU_Command_Ready) || (mem_read_en && !Read_Valid);
    assign Pipeline_EN = !CPU_Stall;

    // ============================================================
    // Instruction Fields
    // ============================================================

    assign OpD    = InstrD[31:26];
    assign FmtD   = InstrD[25:21];
    assign FunctD = InstrD[5:0];

    assign RsD = InstrD[25:21];
    assign RtD = InstrD[20:16];
    assign RdD = InstrD[15:11];

    // COP1 single-precision fields
    assign FRtD = InstrD[20:16];
    assign FRsD = InstrD[15:11];
    assign FRdD = InstrD[10:6];

    // ============================================================
    // Fetch Stage
    // ============================================================

    Pc_reg pc_register (
        .clk    (clk),
        .reset  (reset),
        .EN     (~StallF & Pipeline_EN),
        .pc_in  (PCNextF),
        .pc_out (PCF)
    );

    instruction_memory #(
        .DEPTH     (1024),
        .INIT_FILE ("./Pipeline_MIPS/program.txt")
    ) instruction_mem (
        .addr    (PCF),
        .rd_data (InstrF)
    );

    Adder #(
        .WIDTH(32)
    ) pc_plus_four_adder (
        .A      (PCF),
        .B      (32'd4),
        .Result (PCPlus4F)
    );

    mux2 #(
        .WIDTH(32)
    ) next_pc_mux (
        .a   (PCPlus4F),
        .b   (PCBranchD),
        .sel (PCSrcD),
        .y   (PCNextF)
    );

    IF_ID_Reg if_id_register (
        .clk      (clk),
        .reset    (reset),
        .EN       (~StallD & Pipeline_EN),
        .CLR      (PCSrcD),
        .PCPlus4F (PCPlus4F),
        .InstrF   (InstrF),
        .PCPlus4D (PCPlus4D),
        .InstrD   (InstrD)
    );

    // ============================================================
    // Decode Stage
    // ============================================================

    Control_Unit control_unit (
        .op          (OpD),
        .fmt         (FmtD),
        .funct       (FunctD),

        .MemSizeD    (MemSizeD),
        .MemtoRegD   (MemtoRegD),
        .MemWriteD   (MemWriteD),
        .BranchD     (BranchD),
        .ALUControlD (ALUControlD),
        .ALUSrcD     (ALUSrcD),
        .RegDstD     (RegDstD),
        .RegWriteD   (RegWriteD),

        .FpuRegD     (FpuRegD),
        .FpuConD     (FpuConD)
    );

    Register_File integer_register_file (
        .clk      (clk),
        .rst      (reset),

        .rd_addr1 (RsD),
        .rd_addr2 (RtD),

        .wr_en3   (RegWriteW),
        .wr_addr3 (WriteRegW),
        .wr_data3 (ResultW),

        .rd_data1 (RD1D),
        .rd_data2 (RD2D)
    );

    Float_Reg float_register_file (
        .clk      (clk),
        .rst      (reset),

        .rd_addr1 (FRsD),
        .rd_addr2 (FRtD),

        .wr_en3   (FpuRegW),
        .wr_addr3 (FRdW),
        .wr_data3 (FPUOutW),

        .rd_data1 (RawFRD1D),
        .rd_data2 (RawFRD2D)
    );

    // WB-to-Decode forwarding for the floating register file
    mux2 #(
        .WIDTH(32)
    ) fpu_decode_a_mux (
        .a   (RawFRD1D),
        .b   (FPUOutW),
        .sel (FForwardSrcA),
        .y   (FRD1D)
    );

    mux2 #(
        .WIDTH(32)
    ) fpu_decode_b_mux (
        .a   (RawFRD2D),
        .b   (FPUOutW),
        .sel (FForwardSrcB),
        .y   (FRD2D)
    );

    sign_ext sign_extension (
        .a (InstrD[15:0]),
        .y (SignImmD)
    );

    Shift_Branch branch_shift (
        .SignImmD        (SignImmD),
        .SignImmShiftedD (SignImmShiftedD)
    );

    Adder #(
        .WIDTH(32)
    ) branch_address_adder (
        .A      (PCPlus4D),
        .B      (SignImmShiftedD),
        .Result (PCBranchD)
    );

    // Forward an ALU result from MEM to the branch comparator
    mux2 #(
        .WIDTH(32)
    ) branch_operand_a_mux (
        .a   (RD1D),
        .b   (ALUOutM),
        .sel (ForwardAD),
        .y   (BranchSrcAD)
    );

    mux2 #(
        .WIDTH(32)
    ) branch_operand_b_mux (
        .a   (RD2D),
        .b   (ALUOutM),
        .sel (ForwardBD),
        .y   (BranchSrcBD)
    );

    equal branch_comparator (
        .SrcA  (BranchSrcAD),
        .SrcB  (BranchSrcBD),
        .Equal (EqualD)
    );

    // Do not take a branch while its operands are stalled
    assign PCSrcD =
        BranchD &&
        EqualD  &&
        !StallD;

    assign ControlD = {
        RegWriteD,
        MemtoRegD,
        MemWriteD,
        ALUSrcD,
        RegDstD
    };

    // ============================================================
    // ID/EX Pipeline Register
    // ============================================================

    ID_EX_Reg id_ex_register (
        .clk         (clk),
        .reset       (reset),
        .CLR         (FlushE),
        .EN          (Pipeline_EN),

        .ControlD    (ControlD),
        .ALUControlD (ALUControlD),
        .MemSizeD    (MemSizeD),

        .FpuRegD     (FpuRegD),
        .FpuConD     (FpuConD),

        .RD1D        (RD1D),
        .RD2D        (RD2D),
        .SignImmD    (SignImmD),

        .RsD         (RsD),
        .RtD         (RtD),
        .RdD         (RdD),

        .FRD1D       (FRD1D),
        .FRD2D       (FRD2D),

        .FRsD        (FRsD),
        .FRtD        (FRtD),
        .FRdD        (FRdD),

        .ControlE    (ControlE),
        .ALUControlE (ALUControlE),
        .MemSizeE    (MemSizeE),

        .FpuRegE     (FpuRegE),
        .FpuConE     (FpuConE),

        .RD1E        (RD1E),
        .RD2E        (RD2E),
        .SignImmE    (SignImmE),

        .RsE         (RsE),
        .RtE         (RtE),
        .RdE         (RdE),

        .FRD1E       (FRD1E),
        .FRD2E       (FRD2E),

        .FRsE        (FRsE),
        .FRtE        (FRtE),
        .FRdE        (FRdE)
    );

    assign RegWriteE = ControlE[4];
    assign MemtoRegE = ControlE[3];
    assign MemWriteE = ControlE[2];
    assign ALUSrcE   = ControlE[1];
    assign RegDstE   = ControlE[0];

    // ============================================================
    // Execute Stage
    // ============================================================

    Mux3to1 #(
        .WIDTH(32)
    ) integer_forward_a_mux (
        .in0 (RD1E),
        .in1 (ResultW),
        .in2 (ALUOutM),
        .sel (ForwardAE),
        .out (SrcAE)
    );

    Mux3to1 #(
        .WIDTH(32)
    ) integer_forward_b_mux (
        .in0 (RD2E),
        .in1 (ResultW),
        .in2 (ALUOutM),
        .sel (ForwardBE),
        .out (ForwardedBE)
    );

    mux2 #(
        .WIDTH(32)
    ) alu_source_b_mux (
        .a   (ForwardedBE),
        .b   (SignImmE),
        .sel (ALUSrcE),
        .y   (SrcBE)
    );

    // Store data must use the forwarded value
    assign WriteDataE = ForwardedBE;

    mux2 #(
        .WIDTH(5)
    ) destination_register_mux (
        .a   (RtE),
        .b   (RdE),
        .sel (RegDstE),
        .y   (WriteRegE)
    );

    ALU integer_alu (
        .SrcA       (SrcAE),
        .SrcB       (SrcBE),
        .ALUControl (ALUControlE),
        .ALUResult  (ALUOutE)
    );

    // FPU forwarding
    Mux3to1 #(
        .WIDTH(32)
    ) fpu_forward_a_mux (
        .in0 (FRD1E),
        .in1 (FPUOutW),
        .in2 (FPUOutM),
        .sel (FForwardAE),
        .out (FPUOperandA)
    );

    Mux3to1 #(
        .WIDTH(32)
    ) fpu_forward_b_mux (
        .in0 (FRD2E),
        .in1 (FPUOutW),
        .in2 (FPUOutM),
        .sel (FForwardBE),
        .out (FPUOperandB)
    );

    fpu_top floating_point_unit (
        .A            (FPUOperandA),
        .B            (FPUOperandB),
        .Op_Sub       (FpuConE),
        .Final_Result (FPUOutE)
    );

    // ============================================================
    // EX/MEM Pipeline Register
    // ============================================================

    EX_MEM_Reg ex_mem_register (
        .clk        (clk),
        .reset      (reset),
        .En         (Pipeline_EN),

        .ControlE   ({
            RegWriteE,
            MemtoRegE,
            MemWriteE
        }),

        .FpuRegE    (FpuRegE),
        .MemSizeE   (MemSizeE),

        .ALUOutE    (ALUOutE),
        .WriteDataE (WriteDataE),
        .WriteRegE  (WriteRegE),

        .FPUOutE    (FPUOutE),
        .FRdE       (FRdE),

        .ControlM   (ControlM),
        .FpuRegM    (FpuRegM),
        .MemSizeM   (MemSizeM),

        .ALUOutM    (ALUOutM),
        .WriteDataM (WriteDataM),
        .WriteRegM  (WriteRegM),

        .FPUOutM    (FPUOutM),
        .FRdM       (FRdM)
    );

    assign RegWriteM = ControlM[2];
    assign MemtoRegM = ControlM[1];
    assign MemWriteM = ControlM[0];

    // // ============================================================
    // // Memory Stage
    // // ============================================================

    // Data_Memory data_memory (
    //     .clk       (clk),
    //     .WE        (MemWriteM),
    //     .Address   (ALUOutM),
    //     .WriteData (WriteDataM),
    //     .ReadData  (ReadDataM)
    // );

    assign mem_addr       = ALUOutM;
    assign mem_write_data = WriteDataM;
    assign mem_write_en   = MemWriteM;
    assign mem_read_en    = MemtoRegM;
    assign output_size    = MemSizeM;

    assign ReadDataM      = mem_read_data;
    

    // ============================================================
    // MEM/WB Pipeline Register
    // ============================================================

    MEM_WB_Reg mem_wb_register (
        .clk       (clk),
        .reset     (reset),
        .En        (Pipeline_EN),

        .ControlM  ({
            RegWriteM,
            MemtoRegM
        }),

        .FpuRegM   (FpuRegM),

        .ReadDataM (ReadDataM),
        .ALUOutM   (ALUOutM),
        .WriteRegM (WriteRegM),

        .FPUOutM   (FPUOutM),
        .FRdM      (FRdM),

        .ControlW  (ControlW),
        .FpuRegW   (FpuRegW),

        .ReadDataW (ReadDataW),
        .ALUOutW   (ALUOutW),
        .WriteRegW (WriteRegW),

        .FPUOutW   (FPUOutW),
        .FRdW      (FRdW)
    );

    assign RegWriteW = ControlW[1];
    assign MemtoRegW = ControlW[0];

    // ============================================================
    // Writeback Stage
    // ============================================================

    mux2 #(
        .WIDTH(32)
    ) integer_writeback_mux (
        .a   (ALUOutW),
        .b   (ReadDataW),
        .sel (MemtoRegW),
        .y   (ResultW)
    );

    // ============================================================
    // Hazard Unit
    // ============================================================

    Hazard_Unit hazard_unit (
        .OpD          (OpD),

        .RsD          (RsD),
        .RtD          (RtD),

        .RsE          (RsE),
        .RtE          (RtE),

        .WriteRegE    (WriteRegE),
        .WriteRegM    (WriteRegM),
        .WriteRegW    (WriteRegW),

        .RegWriteE    (RegWriteE),
        .RegWriteM    (RegWriteM),
        .RegWriteW    (RegWriteW),

        .MemtoRegE    (MemtoRegE),
        .MemtoRegM    (MemtoRegM),

        .BranchD      (BranchD),

        .FRsD         (FRsD),
        .FRtD         (FRtD),

        .FRsE         (FRsE),
        .FRtE         (FRtE),

        .FRdM         (FRdM),
        .FRdW         (FRdW),

        .FpuRegD      (FpuRegD),
        .FpuRegE      (FpuRegE),
        .FpuRegM      (FpuRegM),
        .FpuRegW      (FpuRegW),

        .ForwardAD    (ForwardAD),
        .ForwardBD    (ForwardBD),

        .ForwardAE    (ForwardAE),
        .ForwardBE    (ForwardBE),

        .FForwardAE   (FForwardAE),
        .FForwardBE   (FForwardBE),

        .FForwardSrcA (FForwardSrcA),
        .FForwardSrcB (FForwardSrcB),

        .StallF       (StallF),
        .StallD       (StallD),
        .FlushE       (FlushE)
    );

endmodule
