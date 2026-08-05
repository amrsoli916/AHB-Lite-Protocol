module Time_Out (
    //from slave to check howmany time slave transimitte HREADY = 0
    input logic HREADY,

    //clock and reset
    input logic HCLK,
    input logic HRESET_n,

    //output to check how many slave not ready 
    output logic TimeOut
);

logic [3:0] counter;

always_ff @(posedge HCLK or negedge HRESET_n) begin 
    if (!HRESET_n) begin
        TimeOut <= 0;
        counter <= 0;
    end
    else begin
        TimeOut <= 0;
        if(!HREADY)begin
            
            if(counter == 4'd15)begin
                TimeOut <= 1;
                counter <= 0;
            end
            else begin
                counter <= counter + 1;
            end
        end
        else begin
            counter <= 0;
        end
    end
end 
endmodule