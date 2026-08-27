module write_handler #(parameter ADDRESS_WIDTH=7) (w_clk,w_rst,w_en,full,g_w_address,g_r_address,b_w_address);
    input w_clk; //Write clock
    input w_en; //write enable
    input w_rst; //async active low Write reset
    input [ADDRESS_WIDTH : 0] g_r_address; //gray address comes from read domain
    output full; //full flag
    output [ADDRESS_WIDTH : 0] g_w_address; //gray address sent to read domain
    output [ADDRESS_WIDTH-1 : 0] b_w_address; //binary address sent to FIFO Memory

    reg [ADDRESS_WIDTH : 0] w_ptr; //write pointerr

    binary_to_gray #(.ADDRESS_WIDTH(ADDRESS_WIDTH))bin2gray_ins (
        .binary(w_ptr),.gray(g_w_address));

    always @(posedge w_clk or negedge w_rst) begin
        if(!w_rst)begin
            w_ptr<=0;
        end
        else if(w_en) begin
            w_ptr<=w_ptr+1;
        end
    end

    assign b_w_address = w_ptr [ADDRESS_WIDTH-1 : 0];
    assign full = ((g_w_address[ADDRESS_WIDTH] != g_r_address[ADDRESS_WIDTH]) &&
                   (g_w_address[ADDRESS_WIDTH-1] != g_r_address[ADDRESS_WIDTH-1])&&
                   (g_w_address[ADDRESS_WIDTH-2:0] == g_r_address[ADDRESS_WIDTH-2:0]))? 1'b1 : 1'b0;
endmodule