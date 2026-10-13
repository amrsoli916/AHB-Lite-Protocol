module slave_peripheral_interface #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Global Input
    input clk, // NEVER USED

    // input from master
    input [1:0] i_htrans,

    // Inputs from transfer decoder
    input i_transfer_valid,
    input i_read,
    input i_write,

    // Inputs from Address & Control Register
    input [ADDR_WIDTH-1:0] i_addr_reg,
    input [2:0] i_size_reg,
    input [3:0] i_prot_reg,

    // Inputs from Peripheral
    input [DATA_WIDTH-1:0] i_periph_rdata,

    // Input from AHB-Bus
    input [DATA_WIDTH-1:0] i_hwdata,

    // Output to AHB-Bus
    output reg [DATA_WIDTH-1:0] o_hrdata,

    // Outputs to generic peripheral
    output reg o_periph_valid,
    output reg o_periph_read,
    output reg o_periph_write,
    output reg [ADDR_WIDTH-1:0] o_periph_addr,
    output reg [DATA_WIDTH-1:0] o_periph_wdata,
    output reg [2:0] o_periph_size,
    output reg [3:0] o_periph_prot
);
reg w;
always@(posedge clk) begin
    w <= i_write;
end
always@(*) begin
    // Default Values to prevent latches
    o_periph_addr  = 0;
    o_periph_valid = 0;
    o_periph_size  = 0;
    o_periph_prot  = 0;
    o_periph_wdata = 0;
    //o_periph_write = 0;
    //o_periph_read  = 0;
    o_hrdata       = i_periph_rdata; //???

    if (i_transfer_valid) begin
        o_periph_addr  = i_addr_reg;
        o_periph_size  = i_size_reg;
        o_periph_prot  = i_prot_reg;
        o_periph_valid = 1;

        if(w) begin
            //o_periph_write = 1;
            o_periph_wdata = i_hwdata; //make it comb or seq ??????
        end
        /*if (i_read) begin
            //o_periph_read = 1;
            //o_hrdata      = i_periph_rdata;
        end*/
        
    end
    /*else begin
        o_periph_valid = 0;
        o_periph_wdata = 0;
        o_periph_read  = 0;
        o_periph_write = 0;
    end*/
end

always @(posedge clk) begin
    o_periph_write <= 0;
    // o_periph_read  <= 0;
    if(i_transfer_valid) begin
        if (i_write /*&& i_htrans !=0*/) begin
            o_periph_write <= 1;
        end
        // if (i_read && i_htrans !=0) begin
        //     o_periph_read <= 1;
        // end
    end
end

always @(*) begin
    o_periph_read  = 0;
    if(i_transfer_valid) begin
        if (i_read /*&& i_htrans !=0*/) begin
            o_periph_read = 1;
        end
    end
end

endmodule