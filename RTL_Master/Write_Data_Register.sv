module Write_Data_Register(

    input  logic        HCLK,
    input  logic        HRESET_n,

    input  logic        Address_Accepted,
    input logic         CPU_HWRITE,
    input  logic [31:0] CPU_HWDATA,

    output logic [31:0] HWDATA

);

logic Capture_Write_Data;

always_ff @(posedge HCLK or negedge HRESET_n) begin

    if(!HRESET_n)
        HWDATA <= '0;

    else if(Capture_Write_Data)
        HWDATA <= CPU_HWDATA;

end

assign Capture_Write_Data = Address_Accepted && CPU_HWRITE;

endmodule