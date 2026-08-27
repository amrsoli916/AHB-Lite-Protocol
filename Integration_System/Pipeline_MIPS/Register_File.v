// Module      : Register_File
// Description : 32 x 32-bit Integer Register File
// - Two asynchronous read ports
// - One synchronous write port
// - Synchronous active-high reset
// - Register $zero is hardwired to zero
// - Same-cycle write-through forwarding
//=====================================================================
module Register_File (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  rd_addr1,
    input  wire [4:0]  rd_addr2,
    input  wire        wr_en3,
    input  wire [4:0]  wr_addr3,
    input  wire [31:0] wr_data3,
    output wire [31:0] rd_data1,
    output wire [31:0] rd_data2
);
    reg [31:0] register_file [0:31];
   integer i;
always @(posedge clk) begin
    // Clear all registers during synchronous reset
    if (rst) begin
        for (i = 0; i < 32; i = i + 1)
            register_file[i] <= 32'b0;
    end
    // Write data on the rising clock edge , Register zero cannot be written
    else if (wr_en3 && (wr_addr3 != 5'd0)) begin
        register_file[wr_addr3] <= wr_data3;
    end
end
// Asynchronous read port 1 , Return zero for $zero ,Forward write data if reading and writing the same register
assign rd_data1 =
    (rd_addr1 == 5'd0) ? 32'b0 :
    (wr_en3 && (wr_addr3 != 5'd0) &&
     (rd_addr1 == wr_addr3)) ? wr_data3 :
    register_file[rd_addr1];
// Asynchronous read port 2 , Return zero for $zero , Forward write data if reading and writing the same register
assign rd_data2 =
    (rd_addr2 == 5'd0) ? 32'b0 :
    (wr_en3 && (wr_addr3 != 5'd0) &&
     (rd_addr2 == wr_addr3)) ? wr_data3 :
    register_file[rd_addr2];

endmodule
