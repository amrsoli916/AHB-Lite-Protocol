module AHB_Decoder (
    // Global Inputs
    input logic       HCLK,
    input logic        rst_n,

    // Inputs to Slave from Master
    input logic [31:0] HADDR,
    input logic        HREADY,

    // Outputs from Master to Slave
    output logic HSEL_1,
    output logic HSEL_2,

    output logic MUX_SEL_1
);

localparam logic [31:0] Base_Addr_1 = 32'h000_0000;
localparam logic [31:0] Base_Addr_2 = 32'h000_0400;

localparam logic [31:0] ADDR_MASK   = 32'hFFFF_FC00;

logic next_Mux_Sel;


always_comb begin 
    HSEL_1       = 1'b0;
    HSEL_2       = 1'b0;
    next_Mux_Sel = 1'b0;


    if((HADDR & ADDR_MASK) == Base_Addr_1) begin
        HSEL_1       = 1'b1;
        HSEL_2       = 1'b0;
        next_Mux_Sel = 1'b0;
    end
    else begin
        HSEL_1       = 1'b0;
        HSEL_2       = 1'b1;
        next_Mux_Sel = 1'b1;
    end
end

always_ff @(posedge HCLK or negedge rst_n) begin
    if(!rst_n) begin
        MUX_SEL_1 <= 1'b0;
    end
    else /*if(HREADY)*/ begin
        MUX_SEL_1 <= next_Mux_Sel;
    end
end
    
endmodule