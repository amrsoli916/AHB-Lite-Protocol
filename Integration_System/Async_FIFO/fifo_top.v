module fifo_top #(parameter FIFO_WIDTH=8,FIFO_DEPTH=128) (
    w_clk,r_clk,rst,w_data,w_en,r_data,r_en,full,empty
);
    parameter ADDRESS_WIDTH=$clog2(FIFO_DEPTH);
    input w_clk , r_clk , rst; //write clock ,read clock and active low reset
    input w_en , r_en; //write enable and read enable
    input [FIFO_WIDTH-1 : 0] w_data; //written data
    output [FIFO_WIDTH-1 : 0] r_data; //read data

    output full,empty; //full and empty flags
    wire w_en_signal,r_en_signal; //write and read enable signals for the handlers and Memory
    wire [ADDRESS_WIDTH-1:0] b_w_address,b_r_address; //binary read and write addresses for the Memory
    wire [ADDRESS_WIDTH:0] g_w_address_i,g_w_address_o; //gray address of writing input to syncronizet
    wire [ADDRESS_WIDTH:0] g_r_address_i,g_r_address_o; //gray address of reading input to syncronizet
    wire w_rst,r_rst; //output of reset syncronizers

    write_handler #(.ADDRESS_WIDTH(ADDRESS_WIDTH)) w_handler_ins (
        .w_clk(w_clk),.w_rst(w_rst),.w_en(w_en_signal),.full(full),.g_w_address(g_w_address_i),.g_r_address(g_r_address_o),.b_w_address(b_w_address));
    
    syncronizer #(.WIDTH(ADDRESS_WIDTH)) write_domain_sync (
        .in(g_r_address_i),.clk(w_clk),.out(g_r_address_o)
    );

    syncronizer #(.WIDTH(ADDRESS_WIDTH)) read_domain_sync (
        .in(g_w_address_i),.clk(r_clk),.out(g_w_address_o)
    );

    syncronizer #(.WIDTH(1'b0)) w_reset_sync (
        .in(rst),.clk(w_clk),.out(w_rst)
    );

    syncronizer #(.WIDTH(1'b0)) r_reset_sync (
        .in(rst),.clk(r_clk),.out(r_rst)
    );
    
    read_handler #(.ADDRESS_WIDTH(ADDRESS_WIDTH)) r_handler_ins (
        .r_clk(r_clk),.r_rst(r_rst),.r_en(r_en_signal),.empty(empty),.g_w_address(g_w_address_o),.g_r_address(g_r_address_i),.b_r_address(b_r_address));

    assign w_en_signal=w_en&~full;
    assign r_en_signal=r_en&~empty;

    Memory #(.FIFO_WIDTH(FIFO_WIDTH),.FIFO_DEPTH(FIFO_DEPTH)) FIFO_MEMORY (
        .w_en(w_en_signal),.rd_en(r_en_signal),.w_data(w_data),.w_address(b_w_address),.r_data(r_data),.r_address(b_r_address),.w_clk(w_clk),.r_clk(r_clk)
    );
endmodule