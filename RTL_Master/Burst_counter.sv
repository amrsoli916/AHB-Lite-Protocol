module Burst_counter(
    input logic HCLK,
    input logic HRESET_n,

    //control
    input logic Decrement_counter,
    input logic Load_Counter,

    //AHB
    input logic [2:0] HBURST,
    input logic End_Incr_Burst,

    //output 
    output logic TransferDone
);

localparam logic [2:0] SINGLE = 3'b000;
localparam logic [2:0] INCR   = 3'b001;
localparam logic [2:0] WRAP4  = 3'b010;
localparam logic [2:0] INCR4  = 3'b011;
localparam logic [2:0] WRAP8  = 3'b100;
localparam logic [2:0] INCR8  = 3'b101;
localparam logic [2:0] WRAP16 = 3'b110;
localparam logic [2:0] INCR16 = 3'b111;

logic [4:0] beat_counter;
logic [4:0] burst_length;

//////////////////////////////////////////////
//Decode Burst Lenght
/////////////////////////////////////////////

always_comb begin 
    case (HBURST)
       SINGLE         :  burst_length = 5'd1;       //single Burst
       INCR           :  burst_length = 5'd0;       //INC Burst (undefined)
       WRAP4, INCR4   :  burst_length = 5'd4;       //Wrapping 4
       WRAP8, INCR8   :  burst_length = 5'd8;       //Wrapping 8
       WRAP16, INCR16 :  burst_length = 5'd16;      //Wrapping 16
        default: burst_length = 5'd1;               // Defult Single Burst
    endcase
    
end

//////////////////////////////////////////////
//Counter + First beat
/////////////////////////////////////////////

always_ff @(posedge HCLK or negedge HRESET_n ) begin : blockName
    if(!HRESET_n) begin
        beat_counter <= 0;
    end
    else begin
        if (Load_Counter) begin
            beat_counter <= burst_length;
        end
        else if (Decrement_counter) begin
            if (beat_counter != 0) begin
                beat_counter <= beat_counter -1;
            end
        end
    end
end

//////////////////////////////////////////////
//TransferDone
///////////////////////////////////////////////

assign TransferDone = (HBURST == INCR)? End_Incr_Burst : ((beat_counter == 5'd1) && Decrement_counter);

endmodule