// Module      : Float_Register_File
// Description : 32 x 32-bit Floating Point Register File
// Features:
// - Two asynchronous read ports
// - One synchronous write port
// - Synchronous active-high reset
// - Initializes all floating-point registers to zero
//=====================================================================
module Float_Reg(
    input  wire        clk,
    input  wire        rst,
    // Read Port 1 (FRs)
    input  wire [4:0]  rd_addr1,
    // Read Port 2 (FRt)
    input  wire [4:0]  rd_addr2,
    // Write Port (FRd)
    input  wire        wr_en3,
    input  wire [4:0]  wr_addr3,
    input  wire [31:0] wr_data3,
    // Read Data
    output wire [31:0] rd_data1,
    output wire [31:0] rd_data2

);
    // Floating-Point Registers
    reg [31:0] float_regs [0:31];
    integer i;
    // Synchronous Reset and Write
    always @(posedge clk)
	begin
        if (rst) 
		begin
            // Clear all floating-point registers
            for (i = 0; i < 32; i = i + 1) 
			begin
                float_regs[i] <= 32'b0;
            end
            // Test initialization
            // $f0 = 1.5  = 0x3FC00000
            // $f1 = 2.25 = 0x40100000
            //float_regs[0] <= 32'h3FC00000;
            // float_regs[1] <= 32'h40100000;
        end
        else if (wr_en3) 
		begin
            float_regs[wr_addr3] <= wr_data3;
        end
    end
    // Asynchronous Read Port 1
    assign rd_data1 = float_regs[rd_addr1];
    // Asynchronous Read Port 2
    assign rd_data2 = float_regs[rd_addr2];

endmodule
