module slave_ram #(
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 32,
    parameter MEM_DEPTH     = 1024,
    parameter ADDR_PIPELINE = 0,
    parameter DOUT_PIPELINE = 0,
    parameter PARITY_ENABLE = 0
)(
    // Inputs to Slave from Master
    input HCLK,
    input HSEL,
    input HWRITE,
    input HMASTLOCK,
    input [2:0] HSIZE,
    input [ADDR_WIDTH-1:0] HADDR,
    input [2:0] HBURST,
    input [3:0] HPROT,
    input [1:0] HTRANS,
    input [DATA_WIDTH-1:0] HWDATA,

    input FORCE_ERROR,
    // input FORCE_WAIT,
    input RST,

    // Outputs from Master to Slave
    output [DATA_WIDTH-1:0] HRDATA,
    output HREADY,
    output HRESP,

    output parity_out
);

    wire periph_ready;
    wire rst_sync;
    wire periph_error;
    wire slave_write_2;
    wire slave_read_2;
    wire slave_valid_2;
    wire wen;
    wire [ADDR_WIDTH-1:0] slave_addr_2;
    wire [DATA_WIDTH-1:0] write_data_slave_2;
    wire [DATA_WIDTH-1:0] read_data_slave_2;
    reg [DATA_WIDTH-1:0] data;
    reg [DATA_WIDTH-1:0] wdata;
    reg [DATA_WIDTH-1:0] wdata_2;

    // AHB-Slave Instantion
    AHB_Lite_Slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) SLAVE (
        .HCLK(HCLK),
        .HRESETn(AHB_RSTn),
        .HSEL(HSEL),
        .HWRITE(HWRITE),
        .HMASTLOCK(HMASTLOCK),
        .HSIZE(HSIZE),
        .HADDR(HADDR),
        .HBURST(HBURST),
        .HPROT(HPROT),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),
        .PERIPH_READY(periph_ready),
        .PERIPH_ERROR(periph_error),
        .PERIPH_RDATA(read_data_slave_2),
        .ADDRESS(slave_addr_2),
        .WDATA(write_data_slave_2),
        .SIZE(slave_size_2),
        .PROT(slave_prot_2),
        .VALID(slave_valid_2),
        .READ(slave_read_2),
        .WRITE(slave_write_2),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP)
    );

    always @(*) begin
        data =write_data_slave_2;
    end

    // Slave Peripheral (Memory) Instantion
    spr_sync_ram #(
        .MEM_WIDTH(DATA_WIDTH), 
        .ADDR_SIZE(ADDR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH),
        .ADDR_PIPELINE(ADDR_PIPELINE),
        .DOUT_PIPELINE(DOUT_PIPELINE),
        .PARITY_ENABLE(PARITY_ENABLE)
        ) SLAVE_PERIPHERAL (
            .din(data),
            .addr(slave_addr_2),
            .wr_en(slave_write_2),
            .rd_en(slave_read_2),
            .blk_select(slave_valid_2),
            .addr_en(0),
            .dout_en(0),
            .clk(HCLK),
            .rst(rst_sync),
            .dout(read_data_slave_2),
            .parity_out(parity_out),
            .force_error(FORCE_ERROR),
            // .force_wait(FORCE_WAIT),
            .mem_ready(periph_ready),
            .mem_error(periph_error)
        );

        // Active-High reset sync
        rst_sync sync (
            .clk(HCLK),
            .rst(RST),
            .q(rst_sync)
        );
endmodule