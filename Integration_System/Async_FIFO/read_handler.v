module read_handler #(parameter ADDRESS_WIDTH=7) (r_clk,r_rst,r_en,empty,g_w_address,g_r_address,b_r_address);
    input r_clk; //Read clock
    input r_en; //read enable
    input r_rst; //async active low read reset
    input [ADDRESS_WIDTH : 0] g_w_address; //gray address comes from write domain
    output empty; //empty flag
    output [ADDRESS_WIDTH : 0] g_r_address; //gray address sent to read domain
    output [ADDRESS_WIDTH-1 : 0] b_r_address; //binary address sent to FIFO Memory

    reg [ADDRESS_WIDTH : 0] r_ptr; //read pointer

    binary_to_gray #(.ADDRESS_WIDTH(ADDRESS_WIDTH))bin2gray_ins (
        .binary(r_ptr),.gray(g_r_address));

    always @(posedge r_clk or negedge r_rst) begin
        if(!r_rst)begin
            r_ptr<=0;
        end
        else if(r_en) begin
            r_ptr<=r_ptr+1;
        end
    end

    assign b_r_address = r_ptr[ADDRESS_WIDTH-1 : 0];
    assign empty = (g_r_address == g_w_address)? 1'b1 : 1'b0;
endmodule