module UART #(
    parameter CLK_HZ       = 50000000,
    parameter BIT_RATE     = 9600,
    parameter PAYLOAD_BITS = 8
)(
    input                      clk,
    input                      rst_n,

    // --------------------------------------------------
    // Parallel Interface (To/From your Slave)
    // --------------------------------------------------
    
    // Parallel Input: Data you want to transmit
    input   [PAYLOAD_BITS-1:0] tx_data_in,
    input                      tx_en,
    output                     tx_busy,

    // Parallel Output: Data you have received
    output  [PAYLOAD_BITS-1:0] rx_data_out,
    output                     rx_valid,
    output                     rx_break,

    // --------------------------------------------------
    // Serial Interface (External Pins)
    // --------------------------------------------------
    input                      uart_rxd, 
    output                     uart_txd  
);

//
// UART RX Module: Serial IN to Parallel OUT
//
uart_rx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_HZ)
) i_uart_rx (
    .clk          (clk),          
    .resetn       (rst_n),        
    .uart_rxd     (uart_rxd),     // Serial bitstream entering the chip[cite: 2]
    .uart_rx_en   (1'b1),         // Always listening[cite: 2]
    .uart_rx_break(rx_break),     
    .uart_rx_valid(rx_valid),     // Goes high when parallel byte is ready[cite: 2]
    .uart_rx_data (rx_data_out)   // Parallel data exiting to your logic[cite: 2]
);

//
// UART TX Module: Parallel IN to Serial OUT
//
uart_tx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_HZ)
) i_uart_tx (
    .clk          (clk),
    .resetn       (rst_n),
    .uart_txd     (uart_txd),     // Serial bitstream leaving the chip[cite: 2]
    .uart_tx_en   (tx_en),        // Pulse high to start transmission[cite: 2]
    .uart_tx_busy (tx_busy),      // High while sending[cite: 2]
    .uart_tx_data (tx_data_in)    // Parallel data entering from your logic[cite: 2]
);

endmodule