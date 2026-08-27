module Control_Unit (
    input  wire [5:0] op,
    input  wire [4:0] fmt,
    input  wire [5:0] funct,

    output reg        MemtoRegD,
    output reg        MemWriteD,
    output reg        BranchD,
    output reg [2:0]  ALUControlD,
    output reg        ALUSrcD,
    output reg        RegDstD,
    output reg        RegWriteD,

    output reg        FpuRegD,
    output reg        FpuConD,

    output reg        MemSizeD
);

    reg [1:0] ALUOpD;

    always @(*) begin

        // Default control values
        MemtoRegD = 1'b0;
        MemWriteD = 1'b0;
        BranchD   = 1'b0;
        ALUSrcD   = 1'b0;
        RegDstD   = 1'b0;
        RegWriteD = 1'b0;
        FpuRegD   = 1'b0;
        FpuConD   = 1'b0;
        MemSizeD  = 1'b0;
        ALUOpD    = 2'b00;

        case (op)
            // Integer R-Type
            6'b000000: begin
                RegWriteD = 1'b1;
                RegDstD   = 1'b1;
                ALUOpD    = 2'b10;
            end
            // lw
            6'b100011: begin
                RegWriteD = 1'b1;
                ALUSrcD   = 1'b1;
                MemtoRegD = 1'b1;
                MemSizeD  = 1'b0;  //word
                ALUOpD    = 2'b00;
            end
            //lb
            6'b100000: begin
                RegWriteD = 1'b1;
                ALUSrcD   = 1'b1;
                MemtoRegD = 1'b1;
                MemSizeD  = 1'b1; // Byte
                ALUOpD    = 2'b00;
            end
            // sw
            6'b101011: begin
                ALUSrcD   = 1'b1;
                MemWriteD = 1'b1;
                MemSizeD  = 1'b0;
                ALUOpD    = 2'b00;
            end
            // sb
            6'b101000: begin
                ALUSrcD   = 1'b1;
                MemWriteD = 1'b1;
                MemSizeD  = 1'b1; // Byte
                ALUOpD    = 2'b00;
            end
            // beq
            6'b000100: begin
                BranchD = 1'b1;
                ALUOpD  = 2'b01;
            end
            // addi
            6'b001000: begin
                RegWriteD = 1'b1;
                ALUSrcD   = 1'b1;
                ALUOpD    = 2'b00;
            end
            // COP1 Floating-Point Instructions
            6'b010001: begin
                // Single-precision format
                if (fmt == 5'b10000) begin
                    case (funct)
                        // add.s
                        6'b000000: begin
                            FpuRegD = 1'b1;
                            FpuConD = 1'b0;
                        end
                        // sub.s
                        6'b000001: begin
                            FpuRegD = 1'b1;
                            FpuConD = 1'b1;
                        end
                        default: begin
                            FpuRegD = 1'b0;
                            FpuConD = 1'b0;
                        end
                    endcase
                end
            end
            default: begin
                MemtoRegD = 1'b0;
                MemWriteD = 1'b0;
                BranchD   = 1'b0;
                ALUSrcD   = 1'b0;
                RegDstD   = 1'b0;
                RegWriteD = 1'b0;
                FpuRegD   = 1'b0;
                FpuConD   = 1'b0;
                MemSizeD  = 1'b0;
                ALUOpD    = 2'b00;
            end
        endcase
    end
    always @(*) begin
        case (ALUOpD)
            // Used by lw, sw and addi
            2'b00: begin
                ALUControlD = 3'b010;
            end
            // Used by beq
            2'b01: begin
                ALUControlD = 3'b110;
            end
            // Integer R-Type decoding
            2'b10: begin
                case (funct)
                    // add
                    6'b100000:
                       ALUControlD = 3'b010;
                    // sub
                    6'b100010:
                        ALUControlD = 3'b110;
                    // and
                    6'b100100:
                        ALUControlD = 3'b000;
                    // or
                    6'b100101:
                        ALUControlD = 3'b001;
                    // slt
                    6'b101010:
                        ALUControlD = 3'b111;
                    default:
                        ALUControlD = 3'b010;
                endcase
            end
            default: begin
                ALUControlD = 3'b010;
            end
        endcase
    end
endmodule
