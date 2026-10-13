module AHB_Lite_Slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Global Inputs
    input HCLK,
    input HRESETn,

    // Inputs from AHB-BUS
    input HSEL, 
    input HWRITE,
    input HMASTLOCK,
    input [2:0] HSIZE,
    input [ADDR_WIDTH-1:0] HADDR,
    input [2:0] HBURST,
    input [3:0] HPROT,
    input [1:0] HTRANS,
    input [DATA_WIDTH-1:0] HWDATA,

    // Inputs from peripheral
    input PERIPH_READY,
    input PERIPH_ERROR,
    input [DATA_WIDTH-1:0] PERIPH_RDATA,

    // Outputs to Peripheral
    output [ADDR_WIDTH-1:0] ADDRESS,
    output [DATA_WIDTH-1:0] WDATA,
    output [2:0] SIZE,
    output [3:0] PROT,
    output VALID,
    output READ,
    output WRITE,

    // Output to AHB-BUS
    output [DATA_WIDTH-1:0] HRDATA,
    output HREADY,
    output HRESP
);

// Internal wires
wire [ADDR_WIDTH-1:0] ADDR_REG;
wire HSEL_REG;
wire HWRITE_REG;
wire HMASTLOCK_REG;
wire [1:0] HTRANS_REG;
wire [3:0] HPROT_REG;
wire [2:0] HBURST_REG;
wire [2:0] HSIZE_REG;
wire transfer_valid;
wire write;
wire read;


slave_addr_ctrl_reg #(.ADDR_WIDTH(ADDR_WIDTH)) SLAVE_REG (
    .clk(HCLK),
    .rst_n(HRESETn),
    .i_hsel(HSEL),
    .i_hwrite(HWRITE),
    .i_hmastlock(HMASTLOCK),
    .i_htrans(HTRANS),
    .i_hprot(HPROT),
    .i_hburst(HBURST),
    .i_hsize(HSIZE),
    .i_haddr(HADDR),
    //.i_capture_transfer(HREADY),// NEVER USED
    .o_hsel_reg(HSEL_REG),
    .o_haddr_reg(ADDR_REG),
    .o_hwrite_reg(HWRITE_REG),
    .o_hmastlock_reg(HMASTLOCK_REG),
    .o_htrans_reg(HTRANS_REG),
    .o_hprot_reg(HPROT_REG),
    .o_hburst_reg(HBURST_REG),
    .o_hsize_reg(HSIZE_REG)
);

slave_transfer_decoder TRANSFER_DECODER (
    .i_hsel_reg(HSEL),
    .i_htrans_reg(HTRANS_REG),
    .clk(HCLK),
    .i_write_reg(HWRITE_REG),
    .i_hready(HREADY),
    .i_hresp(HRESP),
    .o_transfer_valid(transfer_valid),
    .o_write(write),
    .o_read(read),
    .i_write(HWRITE)
);

slave_peripheral_interface #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) PERIPH_INTERFACE (
    .i_transfer_valid(transfer_valid),
    .clk(HCLK), // NEVER USED
    .i_htrans(HTRANS),
    .i_read(read),
    .i_write(write),
    .i_addr_reg(ADDR_REG),
    .i_size_reg(HSIZE_REG),
    .i_prot_reg(HPROT_REG),
    .i_periph_rdata(PERIPH_RDATA),
    .i_hwdata(HWDATA),
    .o_hrdata(HRDATA),
    .o_periph_valid(VALID),
    .o_periph_read(READ),
    .o_periph_write(WRITE),
    .o_periph_addr(ADDRESS),
    .o_periph_wdata(WDATA),
    .o_periph_size(SIZE),
    .o_periph_prot(PROT)
);

slave_response_handler RESPONSE_HANDLER (
    .i_periph_valid(VALID),
    .i_periph_ready(PERIPH_READY),
    .i_periph_error(PERIPH_ERROR),
    .o_hready(HREADY),
    .o_hresp(HRESP)
);

endmodule