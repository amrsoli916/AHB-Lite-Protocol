module UART_TOP#(
    parameter CLK_HZ       = 50000000,
    parameter BIT_RATE     = 9600,
    parameter PAYLOAD_BITS = 8
)(
    input clk,
    input rst_n,
    input [PAYLOAD_BITS-1:0]   tx_data_in_slave,
    input [PAYLOAD_BITS-1:0]   tx_data_in_device,
    input                      tx_en_slave,
    input                      tx_en_device,
    output                     tx_busy_slave,
    output                     tx_busy_device,
    output [PAYLOAD_BITS-1:0]  rx_wdata_out, 
    output [PAYLOAD_BITS-1:0]  rx_rdata_out,
    output rx_valid_write,
    output rx_valid_read,
    output rx_break_write,
    output rx_break_read
    //output rx_valid,
    //output rx_break,
    //input                      uart_rxd, 
    //output                     uart_txd 
);

// Internal Wires
wire f_uart1_t_uart2;
wire f_uart2_t_uart1;

UART #(
    .CLK_HZ(CLK_HZ),
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS)
) UART_1 (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data_in(tx_data_in_slave),
    .tx_en(tx_en_slave),
    .tx_busy(tx_busy_slave),
    .rx_data_out(rx_rdata_out),
    .rx_valid(rx_valid_read),
    .rx_break(rx_break_read),
    .uart_rxd(f_uart2_t_uart1), 
    .uart_txd(f_uart1_t_uart2)
);

UART #(
    .CLK_HZ(CLK_HZ),
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS)
) UART_2 (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data_in(tx_data_in_device),
    .tx_en(tx_en_device),
    .tx_busy(tx_busy_device),
    .rx_data_out(rx_wdata_out),
    .rx_valid(rx_valid_write),
    .rx_break(rx_break_write),
    .uart_rxd(f_uart1_t_uart2), 
    .uart_txd(f_uart2_t_uart1)
);
endmodule