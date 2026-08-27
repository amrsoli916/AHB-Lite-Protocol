module Error_Response (
    input logic P_ERROR,
    input logic P_READY,
    input logic HCLK,
    input logic HRESET_n,
    input logic [31:0] HADDR,
    input logic Data_Phase_Valid,

    output logic HREADYOUT,
    output logic HRESP,
    output logic Error_Complete
);

    /////////////////////////////////////////////
    // Rang Address of Peripheral
    ///////////////////////////////////////////////
    localparam logic [31:0] PERIPH_BASE = 32'h0000_0000;    // start the address Peripheral
    localparam logic [31:0] PERIPH_END  = 32'h0000_00FF;    // End the Address of Peripheral

    logic Address_In_Range;
    logic Error_Condition;
    logic error_cycle_2;

    //check the boundry of peripheral
    assign Address_In_Range = (HADDR >= PERIPH_BASE) && (HADDR <= PERIPH_END);

    //check if occur error 
    assign Error_Condition = Data_Phase_Valid && (P_ERROR || !Address_In_Range);


    always_ff @(posedge HCLK or negedge HRESET_n) begin
        if (!HRESET_n) begin
            error_cycle_2 <= 1'b0;
        end 
        else if (Error_Condition && !error_cycle_2) begin
            error_cycle_2 <= 1'b1;
        end 
        else begin
            error_cycle_2 <= 1'b0;
        end
    end

    always_comb begin 
        if (error_cycle_2) begin
            //In cycle_2 of error 
            HREADYOUT = 1'b1;
            HRESP     = 1'b1;
        end 
        else if (Error_Condition) begin
            //In cycle_1 of error 
            HREADYOUT = 1'b0;
            HRESP     = 1'b1;
        end 
        else begin
            //Defult
            HREADYOUT = P_READY;
            HRESP     = 1'b0;
        end
    end


    assign Error_Complete = error_cycle_2;

endmodule