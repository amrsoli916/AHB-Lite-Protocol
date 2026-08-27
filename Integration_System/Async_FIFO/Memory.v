module Memory #(parameter FIFO_WIDTH=8,FIFO_DEPTH=128) (
    w_en,rd_en,w_data,w_address,r_data,r_address,w_clk,r_clk);

    input w_en,rd_en;
    input [FIFO_WIDTH-1:0] w_data;
    input w_clk,r_clk;
    input [$clog2(FIFO_DEPTH)-1:0] w_address,r_address;
    output reg [FIFO_WIDTH-1:0] r_data;

    reg [FIFO_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    //Write Operation
    always @(posedge w_clk) begin
        if(w_en) begin
             mem[w_address]<=w_data;
        end
    end

    //Read Operation
    always @(posedge r_clk) begin
        if(rd_en)begin
            r_data<=mem[r_address];
        end
    end
endmodule