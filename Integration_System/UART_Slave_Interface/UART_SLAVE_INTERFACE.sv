module UART_SLAVE_INTERFACE#(
    parameter ADDR_WIDTH   = 32,
    parameter DATA_WIDTH   = 32,
    parameter CLK_HZ       = 16000000,
    parameter BIT_RATE     = 16000000,
    parameter PAYLOAD_BITS = 8,
    parameter FIFO_WIDTH   = 8,
    parameter FIFO_DEPTH   = 128
)(
    // Global Inputs
    input AHB_CLK,
    input UART_CLK,
    input AHB_RSTn,
    input UART_RSTn,
    input FIFO_RSTn,

    // Inputs to Slave from Master
    input HSEL,
    input HWRITE,
    input HMASTLOCK,
    input [2:0] HSIZE,
    input [ADDR_WIDTH-1:0] HADDR,
    input [2:0] HBURST,
    input [3:0] HPROT,
    input [1:0] HTRANS,
    input [DATA_WIDTH-1:0] HWDATA,

    // Outputs from Master to Slave
    output [DATA_WIDTH-1:0] HRDATA,
    output HREADY,
    output HRESP,

    // Inputs from peripheral
    //input PERIPH_READY,
    input PERIPH_ERROR,

    // Outputs From UART
    //output  TX_BUSY_WRITE,
    output  TX_BUSY_READ,
    output  WDATA_VALID,
    //output  RDATA_VALID,
    output  BREAK_WRITE,
    output  BREAK_READ,
    output [PAYLOAD_BITS-1:0] WRITTEN_DATA,

    // Inputs to UART
    input [PAYLOAD_BITS-1:0] DATA_DEVICE,
    //input UART_RD_EN,


    // Output Flags of FIFO
    output FULL,
    output EMPTY
);
// LocalParameters
localparam WORD = 3'b010;

// Internal Wires
wire uart_rd_en;
wire uart_reset;
wire rdata_valid;
wire tx_busy_write;
wire uart_wr_en;
wire rdata_valid_sync;
wire fifo_wr_en;
wire fifo_rd_en;
wire slave_read;
wire [2:0] slave_size;
wire [3:0] slave_prot;
wire slave_write;
wire slave_valid;
wire [DATA_WIDTH-1:0]   write_data_slave;
wire [PAYLOAD_BITS-1:0] read_data_uart;
wire [ADDR_WIDTH-1:0]   slave_addr;
wire [PAYLOAD_BITS-1:0] write_data_uart;
wire rdata_valid_pulse;
reg  periph_ready;
reg r;
reg  uart_wr_en_reg;
reg  wait_for_busy;
reg  [PAYLOAD_BITS-1:0] write_data_fifo;
reg  [DATA_WIDTH-1:0]   read_data_slave;
reg  rdata_valid_reg;

// Handling write enable of FIFO
assign fifo_wr_en = /*slave_write && slave_valid;*/ SLAVE.write;

// Handling read enable of FIFO
//assign fifo_rd_en = !tx_busy_write && !EMPTY ;
always @(posedge UART_CLK or negedge UART_RSTn) begin
    if(!UART_RSTn) begin
        wait_for_busy <= 0; // Flag to prevent multiple reads
    end
    else begin
        if (fifo_rd_en) begin
            wait_for_busy <= 1;
        end
        else if (tx_busy_write) begin
            wait_for_busy <= 1'b0;
        end
    end
end
assign fifo_rd_en = !tx_busy_write && !EMPTY && !wait_for_busy ;


// Handling Write Enable of UART
// assign uart_wr_en = !EMPTY;
always @(posedge UART_CLK or negedge UART_RSTn) begin
    if(!UART_RSTn) begin
        uart_wr_en_reg <= 0;
    end
    else begin
        uart_wr_en_reg <= fifo_rd_en;
    end
end
assign uart_wr_en = uart_wr_en_reg; 
 

// Handling Read Enable of UART
assign uart_rd_en = 1;

// Handling Data Coming From Slave to UART
always @(*) begin
    //if (slave_size == WORD) begin
        case(slave_addr[1:0])
            2'b00: write_data_fifo = write_data_slave[7:0];
            2'b01: write_data_fifo = write_data_slave[15:8];
            2'b10: write_data_fifo = write_data_slave[23:16];
            2'b11: write_data_fifo = write_data_slave[31:24];
        endcase
    //end
    //else begin
       // write_data_fifo = write_data_slave;
    //end
end

// Handling Data Coming From UART to Slave
always @(*) begin
    //if (slave_size == WORD) begin
        case(slave_addr[1:0])
            2'b00: read_data_slave = {24'b0,read_data_uart};
            2'b01: read_data_slave = {16'b0,read_data_uart,8'b0};
            2'b10: read_data_slave = {8'b0,read_data_uart,16'b0};
            2'b11: read_data_slave = {read_data_uart,24'b0};
        endcase
    //end
    //else begin
        //read_data_slave = read_data_uart;
    //end
end

always @(posedge AHB_CLK) begin
    r <= slave_read;
end
assign periph_ready = (slave_read) ? rdata_valid_pulse : 1'b1;

always @(posedge UART_CLK) begin
    rdata_valid_reg <= rdata_valid;
end

/*// HANDLING PERIPH_READY
always @(*) begin
    periph_ready = 1;
    if (slave_read) begin
        periph_ready = 0;
            if (rdata_valid_sync) begin
                periph_ready = 1;
            end
            else begin
                periph_ready = 0;
            end
        end
    end*/

/*// HANDLING PERIPH_READY -NEW
always @(*) begin
    periph_ready = 1;
    if (slave_read) begin
        periph_ready = 0;
        while (!rdata_valid_sync) begin
            //if (rdata_valid_sync) begin
                //periph_ready = 1;
            //end
            periph_ready = 0;
            //else begin
                //periph_ready = 0;
            //end
        end
        periph_ready = 1;
    end
end*/

// AHB-Slave Instantion
AHB_Lite_Slave #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) SLAVE (
    .HCLK(AHB_CLK),
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
    .PERIPH_ERROR(PERIPH_ERROR),
    .PERIPH_RDATA(read_data_slave),
    .ADDRESS(slave_addr),
    .WDATA(write_data_slave),
    .SIZE(slave_size),
    .PROT(slave_prot),
    .VALID(slave_valid),
    .READ(slave_read),
    .WRITE(slave_write),
    .HRDATA(HRDATA),
    .HREADY(HREADY),
    .HRESP(HRESP)
);

// UART IP Instantion
UART_TOP #(
    .CLK_HZ(CLK_HZ),
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS)
) UART (
    .clk(UART_CLK),
    .rst_n(uart_reset),
    .tx_data_in_slave(write_data_uart),
    .tx_data_in_device(DATA_DEVICE), 
    .tx_en_slave(uart_wr_en),
    .tx_en_device(uart_rd_en),
    .tx_busy_slave(tx_busy_write),
    .tx_busy_device(TX_BUSY_READ),
    .rx_wdata_out(WRITTEN_DATA),
    .rx_rdata_out(read_data_uart),
    .rx_valid_write(WDATA_VALID),
    .rx_valid_read(rdata_valid),
    .rx_break_write(BREAK_WRITE),
    .rx_break_read(BREAK_READ)
); 


// FIFO Instantion
// We used it to solve the problem of CDC from Fast Domain to Slow Domain
fifo_top #(
    .FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) FIFO (
    .w_clk(AHB_CLK),
    .r_clk(UART_CLK),
    .rst(FIFO_RSTn),
    .w_en(fifo_wr_en),
    .r_en(fifo_rd_en),
    .w_data(write_data_fifo),
    .r_data(write_data_uart),
    .full(FULL),
    .empty(EMPTY)
);

// Double Flop Sync Instantion
// We used it to solve the problem of CDC from Slow Domain to Fast Domain
double_flop_sync DOUBLE_FF (
    .clk(AHB_CLK),
    .in(rdata_valid_reg),
    .out(rdata_valid_sync)
);

// Level To Pulse for rdata_valid_sync
level_to_pulse lvl_pulse (
    .clk(AHB_CLK),
    .rst_n(AHB_RSTn),
    .level(rdata_valid_sync),
    .pulse(rdata_valid_pulse)
);

// Reset Synchronizer for UART
rstn_sync rst1 (
    .clk(UART_CLK),
    .rstn(UART_RSTn),
    .d(1),
    .q(uart_reset)
);

endmodule