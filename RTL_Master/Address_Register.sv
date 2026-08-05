module Address_Register (
    //control signal from FSM
    input logic Load_Start_Address,
    input logic Increment_Address,

    //Address from Address Generator and Start Address from CPU
    input logic [31:0] Start_Address,
    input logic [31:0] Next_Address,

    //Clock and Reset
    input logic HCLK,
    input logic HRESET_n,

    //output to Address Generator and AHB
    output logic [31:0] Current_Address
);

always_ff @(posedge HCLK or negedge HRESET_n) begin 
    if(!HRESET_n) begin
        Current_Address <= 32'b0;                           //reset address to 0
    end
    else begin
        if(Load_Start_Address)begin
            Current_Address <= Start_Address;               //load start address to current address
        end
        else if(Increment_Address)begin
            Current_Address <= Next_Address;                //increment current address to next address from address generator
        end
    end
end
    
endmodule