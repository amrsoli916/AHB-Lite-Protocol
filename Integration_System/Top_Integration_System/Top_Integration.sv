module Top_Integration #(
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 32,
    parameter PAYLOAD_BITS  = 8,
    parameter CLK_HZ        = 16000000,
    parameter BIT_RATE      = 16000000,
    parameter FIFO_WIDTH    = 8,
    parameter FIFO_DEPTH    = 128,
    parameter MEM_DEPTH     = 1024,
    parameter ADDR_PIPELINE = 0,
    parameter DOUT_PIPELINE = 0,
    parameter PARITY_ENABLE = 0
)(
    input HCLK,
    input HRESETn,
    input UART_clk,
    input PERIPH_ERROR,
    // input FORCE_WAIT,

    // Outputs From UART
    output TX_BUSY_READ,
    output WDATA_VALID,
    output BREAK_WRITE,
    output BREAK_READ,
    output [PAYLOAD_BITS-1:0] WRITTEN_DATA,

    // Inputs to UART
    input [PAYLOAD_BITS-1:0] DATA_DEVICE,

    // Output Flags of FIFO
    output FULL,
    output EMPTY,

    // Output Flags To CPU
    output CPU_Error,
    output CPU_Data_Ready,

    // Outputs from RAM
    output parity_out
);

// Outputs from Master to Slaves
wire HWRITE;
wire [2:0] HSIZE;
wire [ADDR_WIDTH-1:0] HADDR;
wire [2:0] HBURST;
wire [1:0] HTRANS;
wire [DATA_WIDTH-1:0] HWDATA;

// Outputs from Slave1 to Master
wire [DATA_WIDTH-1:0] HRDATA_1;
wire HREADY_1;
wire HRESP_1;


// Outputs from Slave2 to Master
wire [DATA_WIDTH-1:0] HRDATA_2;
wire HREADY_2;
wire HRESP_2;

// Outputs from MUX to Master
wire [DATA_WIDTH-1:0] HRDATA;
wire HREADY;
wire HRESP;


wire sync_resset;
wire HSEL1;
wire HSEL2;
wire mux_sel;

//instantiation the CPU & Master of AHB
Top_CPU_Master Top_CPU_Master_int(
    .HCLK(HCLK), 
    .HRESET_n(sync_resset), 
    .HBURST(HBURST), 
    .HSIZE(HSIZE),
    .HWRITE(HWRITE), 
    .HTRANS(HTRANS), 
    .HADDR(HADDR), 
    .HWDATA(HWDATA), 
    .HREADY(HREADY), 
    .HRESP(HRESP), 
    .HRDATA(HRDATA), 
    .CPU_Error(CPU_Error), 
    .CPU_Data_Ready(CPU_Data_Ready)
);

//instantiation the slave with the UART_IP
UART_SLAVE_INTERFACE  #(
    .ADDR_WIDTH(ADDR_WIDTH), 
    .DATA_WIDTH(DATA_WIDTH), 
    .CLK_HZ(CLK_HZ), 
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS), 
    .FIFO_WIDTH(FIFO_WIDTH), 
    .FIFO_DEPTH(FIFO_DEPTH)
) UART_SLAVE_INTERFACE_int (
    .AHB_CLK(HCLK), 
    .UART_CLK(UART_clk), 
    .AHB_RSTn(sync_resset),
    .UART_RSTn(HRESETn),
    .FIFO_RSTn(HRESETn),
    .HSEL(HSEL2),
    .HWRITE(HWRITE), 
    .HMASTLOCK(1'b1), 
    .HSIZE(HSIZE),
    .HADDR(HADDR), 
    .HBURST(HBURST), 
    .HPROT(4'b0000), 
    .HTRANS(HTRANS), 
    .HWDATA(HWDATA), 
    .HRDATA(HRDATA_2), 
    .HREADY(HREADY_2), 
    .HRESP(HRESP_2), 
    .PERIPH_ERROR(PERIPH_ERROR), 
    .TX_BUSY_READ(TX_BUSY_READ), 
    .WDATA_VALID(WDATA_VALID),
    .BREAK_WRITE(BREAK_WRITE), 
    .BREAK_READ(BREAK_READ), 
    .WRITTEN_DATA(WRITTEN_DATA), 
    .DATA_DEVICE(DATA_DEVICE),
    .FULL(FULL), 
    .EMPTY(EMPTY)
);

//instantiation the slave with the RAM
slave_ram #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(MEM_DEPTH),
    .ADDR_PIPELINE(ADDR_PIPELINE),
    .DOUT_PIPELINE(DOUT_PIPELINE),
    .PARITY_ENABLE(PARITY_ENABLE)
)periph_2(
    .HCLK(HCLK),
    .HSEL(HSEL1),  
    .HWRITE(HWRITE),
    .HMASTLOCK(1'b1),
    .HSIZE(HSIZE),
    .HADDR(HADDR),
    .HBURST(HBURST),
    .HPROT(4'b0001),
    .HTRANS(HTRANS),
    .HWDATA(HWDATA),
    .FORCE_ERROR(PERIPH_ERROR),
    // .FORCE_WAIT(FORCE_WAIT),
    .RST(~HRESETn),
    .HRDATA(HRDATA_1),
    .HREADY(HREADY_1),
    .HRESP(HRESP_1),
    .parity_out(parity_out)
);


// MUX FOR HRDATA
two_one_mux #(.INPUT_WIDTH(DATA_WIDTH)) MUX1 (
    .sel(mux_sel),
    .in0(HRDATA_1),
    .in1(HRDATA_2),
    .out(HRDATA)
);

// MUX FOR HREADY
two_one_mux #(.INPUT_WIDTH(1)) MUX2 (
    .sel(mux_sel),
    .in0(HREADY_1),
    .in1(HREADY_2),
    .out(HREADY)
);

// MUX FOR HRESP
two_one_mux #(.INPUT_WIDTH(1)) MUX3 (
    .sel(mux_sel),
    .in0(HRESP_1),
    .in1(HRESP_2),
    .out(HRESP)
);

// Decoder
AHB_Decoder DECODER (
    .HCLK(HCLK),
    .rst_n(HRESETn),
    .HADDR(HADDR),
    .HREADY(HREADY),
    .HSEL_1(HSEL1),
    .HSEL_2(HSEL2),
    .MUX_SEL_1(mux_sel)
);

//synchoranizer reset
reset_synchronizer reset_synchronizer_int(
    .HCLK(HCLK), .ext_resset_n(HRESETn), .sync_resset(sync_resset)
);
    
endmodule