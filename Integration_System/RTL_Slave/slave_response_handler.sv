module slave_response_handler (

    // Inputs from Peripheral Interface
    input i_periph_valid,

    // Inputs from peripheral
    input i_periph_ready,
    input i_periph_error,

    // Output to AHB-Bus
    output reg o_hready,
    output reg o_hresp
);

localparam OKAY  = 1'b0;
localparam ERROR = 1'b1;

always @(*) begin
    if (i_periph_valid) begin

        if (i_periph_ready) begin
            o_hready = 1;
        end
        else begin
            o_hready = 0;
        end

        if (i_periph_error) begin
            o_hresp = ERROR;
        end
        else begin
            o_hresp = OKAY;
        end
    end

    else begin
        o_hready = 0;
        o_hresp = OKAY;
    end
end

endmodule