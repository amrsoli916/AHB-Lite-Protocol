module slave_addr_ctrl_reg #(
    parameter ADDR_WIDTH = 32
)(
 // Global Signals
 input clk,
 input rst_n,

 // Inputs from AHB-Lite Bus
 input i_hwrite,
 input i_hmastlock,
 input [1:0] i_htrans,
 input [3:0] i_hprot,
 input [2:0] i_hburst,
 input [2:0] i_hsize,
 input [ADDR_WIDTH-1:0] i_haddr,
 input i_hsel,  
 
 // Input from slave control block
 //input i_capture_transfer, // NEVER USED



 // Registered Outputs
 output reg o_hsel_reg,
 output reg o_hwrite_reg,
 output reg o_hmastlock_reg,
 output reg [1:0] o_htrans_reg,
 output reg [3:0] o_hprot_reg,
 output reg [2:0] o_hburst_reg,
 output reg [2:0] o_hsize_reg,
 output reg [ADDR_WIDTH-1:0] o_haddr_reg
);


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        o_hwrite_reg    <= 0;
        o_hmastlock_reg <= 0;
        o_htrans_reg    <= 0;
        o_hprot_reg     <= 0;
        o_hburst_reg    <= 0;
        o_hsize_reg     <= 0;
        o_haddr_reg     <= 0;
    end

    else begin
        o_hsel_reg      <= i_hsel;
        o_hwrite_reg    <= i_hwrite;
        o_hmastlock_reg <= i_hmastlock;
        o_htrans_reg    <= i_htrans;
        o_hprot_reg     <= i_hprot;
        o_hburst_reg    <= i_hburst;
        o_hsize_reg     <= i_hsize;
        o_haddr_reg     <= i_haddr;
    end   
end
endmodule