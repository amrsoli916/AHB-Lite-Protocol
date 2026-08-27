module Capture_Register (
    input logic HCLK,
    input logic HRESET_n,
    
    //from FSM
    input logic Address_Accepted,

    //CPU control signal
    input logic        CPU_HWRITE,
    input logic [2:0]  CPU_HSIZE,
    input logic [2:0]  CPU_HBURST,

    //output Signals
    output logic       HWRITE_Data_Phase,
    output logic [2:0] HSIZE_Data_Phase,
    output logic [2:0] HBURST_Data_Phase

);

always_ff @(posedge HCLK or negedge HRESET_n) begin 
        if (!HRESET_n) begin
            HWRITE_Data_Phase <= 1'b0;
            HSIZE_Data_Phase <= 3'b0;
            HBURST_Data_Phase <= 3'b0;
        end
        else begin
            if (Address_Accepted) begin
                HWRITE_Data_Phase <= CPU_HWRITE;
                HSIZE_Data_Phase <= CPU_HSIZE;
                HBURST_Data_Phase <= CPU_HBURST;
            end
        end
end

endmodule