module slave_transfer_decoder(
    // Global Input
    input clk,
    // Inputs from slave_addr_ctrl_reg
    input [1:0] i_htrans_reg,
    input i_write_reg,
    input i_hsel_reg,

    // Inputs from response handler
    input i_hready,
    input i_hresp,
    input i_write,


    // Decoder Outputs
    output reg o_transfer_valid,
    output reg o_write,
    output reg o_read
);

localparam IDLE  = 2'b00;
localparam BUSY  = 2'b01;
localparam NOSEQ = 2'b10;
localparam SEQ   = 2'b11;

reg [1:0] htrans_reg;
reg sel;
always @(posedge clk) begin
    htrans_reg <= i_htrans_reg;
    sel        <= i_hsel_reg;
end


always @(*) begin
    // Default Values
    //o_transfer_valid = 0;
    o_write          = 0;
    

    case (htrans_reg)
        //IDLE  : o_transfer_valid = 0;

        //BUSY  : o_transfer_valid = 0;

        NOSEQ : begin
            //o_transfer_valid = 1;
            if (i_write_reg /*&& i_hready && !i_hresp*/) begin
                o_write = 1;
                // o_read  = 0;
            end
            // else if (!i_write_reg /*&& i_hready && !i_hresp*/) begin
            //     o_read  = 1;
            //     o_write = 0;
            // end
        end

        SEQ : begin
            //o_transfer_valid = 1;
            if(i_write_reg /*&& i_hready && !i_hresp*/) begin
                o_write = 1;
                // o_read  = 0;
            end
            // else if (!i_write_reg /*&& i_hready && !i_hresp*/) begin
            //     o_read  = 1;
            //     o_write = 0;
            // end
        end
    endcase
end

//for read 
always @(*) begin
    o_read     = 0;

    case (i_htrans_reg)
        //IDLE  : o_transfer_valid = 0;

        //BUSY  : o_transfer_valid = 0;

        NOSEQ : begin
            //o_transfer_valid = 1;
            // if (i_write_reg /*&& i_hready && !i_hresp*/) begin
            //     // o_write = 1;
            //     o_read  = 0;
            // end
            if (!i_write /*&& i_hready && !i_hresp*/) begin
                o_read  = 1;
                // o_write = 0;
            end
        end

        SEQ : begin
            //o_transfer_valid = 1;
            // if(i_write_reg /*&& i_hready && !i_hresp*/) begin
            //     o_write = 1;
            //     o_read  = 0;
            // end
            if (!i_write /*&& i_hready && !i_hresp*/) begin
                o_read  = 1;
                // o_write = 0;
            end
        end
    endcase
end

always @(posedge clk) begin
    // Default Values
    o_transfer_valid <= 0;
    if(i_hsel_reg) begin
        case (i_htrans_reg)
            IDLE  : o_transfer_valid <= 0;

            BUSY  : o_transfer_valid <= 0;

            NOSEQ : o_transfer_valid <= 1;

            SEQ   : o_transfer_valid <= 1;
        endcase
    end
end

endmodule