module spr_sync_ram(force_error,/*force_wait*/,din,addr,wr_en,rd_en,blk_select,addr_en,dout_en,clk,rst,dout,parity_out,mem_ready,mem_error);
// Defining Parameters
parameter MEM_WIDTH = 16;
parameter MEM_DEPTH = 1024;
parameter ADDR_SIZE = 10;
parameter ADDR_PIPELINE = 1'b0; // False
parameter DOUT_PIPELINE = 1'b0; // False
parameter PARITY_ENABLE = 1'b0; // False
// Defining input and output ports
input[MEM_WIDTH-1:0] din;
input[ADDR_SIZE-1:0] addr;
// input force_wait;
input force_error;
input wr_en,rd_en,blk_select,addr_en,dout_en,clk,rst;
output [MEM_WIDTH-1:0] dout;
output  parity_out,mem_ready,mem_error;

reg  [ADDR_SIZE-1:0] ff_1_out;
wire [ADDR_SIZE-1:0] addr_used;
reg  [MEM_WIDTH-1:0] dout_mem;
reg  [MEM_WIDTH-1:0] ff_2_out;

// Defining Memory
reg [MEM_WIDTH-1:0] mem [0:MEM_DEPTH-1];
// Defining address accoring to addr_pipeline signal
generate
    if(ADDR_PIPELINE) begin
        always@(posedge clk) begin
            if(addr_en) begin
                ff_1_out <= addr;
            end
        end
    end
endgenerate
assign addr_used = (ADDR_PIPELINE)?ff_1_out:addr;

always@(posedge clk) begin

    if(rst) begin
        dout_mem <= 0;
    end
    else if (blk_select) begin
        if(wr_en) begin
            mem[addr_used] <= din;
        end
        // if (rd_en) begin
        //     dout_mem <= mem[addr_used];
        // end
    end
end

always@(*)begin
    // if(rst) begin
    //     dout_mem = 0;
    // end
    if (blk_select) begin
        // if(wr_en) begin
        //     mem[addr_used] = din;
        // end
        if (rd_en) begin
            dout_mem = mem[addr_used];
        end
    end
end

//Defining output according to dout_pipeline signal
generate
    if(DOUT_PIPELINE) begin
        always@(posedge clk) begin
            if(dout_en) begin
                ff_2_out <= dout_mem;
            end
        end
    end
endgenerate
assign dout = (DOUT_PIPELINE)?ff_2_out:dout_mem;
assign parity_out = (PARITY_ENABLE)? ^dout : 1'b0;
assign mem_ready = 1'b1;
assign mem_error = force_error;
endmodule