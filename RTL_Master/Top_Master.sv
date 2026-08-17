module Top_Master #(width = 32)(
    //clock and reset
    input logic HCLK,
    input logic HRESET_n,

    //input from CPU
    input logic             CPU_Last_Transfer,
    input logic [2:0]       CPU_HBURST,
    input logic [2:0]       CPU_HSIZE,
    input logic             CPU_Request,
    input logic             CPU_Busy,
    input logic             CPU_HWRITE,
    //data from CPU to Master
    input logic [width-1:0] CPU_HWDATA,
    //Address from CPU to Master
    input logic [31:0]        CPU_HADDR,

    //input from slave 
    input logic HREADY,
    input logic HRESP,
    //data from slave to Master 
    input logic [width-1:0] HRDATA,

    //output to Slave 
    output logic [2:0] HBURST,
    output logic [2:0] HSIZE,
    output logic HWRITE,
    output logic [1:0] HTRANS,
    //Address to Slave 
    output logic [31:0] HADDR,
    //Data output to slave 
    output logic [width-1:0] HWDATA,

    //output to CPU
    output logic CPU_Error ,                                //if occure error tell CPU                            
    output logic Read_Valid,                                //to tell CPU that the data is valid and ready to read
    output logic CPU_Command_Ready,
    output logic CPU_Data_Ready,                         //to tell CPU that the next burst request is enabled
    //output data to CPU
    output logic [width-1:0] CPU_HRDATA
);
    
logic Load_Counter, Decrement_counter;
logic TransferDone;
logic Load_Start_Address, Increment_Address;
logic Address_Accepted;
logic TimeOut;
logic HWRITE_Data_Phase, Write_Enable;
logic [31:0] Current_Address, Next_Address;
logic [2:0] HSIZE_Data_Phase, HBURST_Data_Phase;
logic First_Beat;

//Write Data Register
Write_Data_Register Write_Data_Register_Inst(
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .Address_Accepted(Address_Accepted),
    .CPU_HWRITE(HWRITE_Data_Phase),
    .CPU_HWDATA(CPU_HWDATA),
    .HWDATA(HWDATA)              //Data Output For this 
);

//Burst Counter
Burst_counter Burst_Counter_Inst(
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .Load_Counter(Load_Counter),
    .Decrement_counter(Decrement_counter),
    .HBURST(CPU_HBURST),
    .HREADY(HREADY),
    .First_Beat(First_Beat),
    .TransferDone(TransferDone),
    .Last_Transfer(CPU_Last_Transfer)
);

//Address Register
Address_Register Address_Register_Inst(
    .Load_Start_Address(Load_Start_Address),
    .Increment_Address(Increment_Address),
    .Start_Address(CPU_HADDR),
    .Next_Address(Next_Address),
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .Current_Address(Current_Address)
);

//Capture Register
Capture_Register Capture_Register_Inst(
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .Address_Accepted(Load_Start_Address),
    .CPU_HWRITE(CPU_HWRITE),
    .CPU_HSIZE(CPU_HSIZE),
    .CPU_HBURST(CPU_HBURST),
    .HWRITE_Data_Phase(HWRITE_Data_Phase),
    .HSIZE_Data_Phase(HSIZE_Data_Phase),
    .HBURST_Data_Phase(HBURST_Data_Phase)
);

//FSM Controller
FSM FSM_Inst(
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .Request(CPU_Request),
    .Busy(CPU_Busy),
    .TransferDone(TransferDone),
    .HREADY(HREADY),
    .HRESP(HRESP),
    .TimeOut(TimeOut),
    .Decrement_counter(Decrement_counter),
    .Load_Counter(Load_Counter),
    .Load_Start_Address(Load_Start_Address),
    .Increment_Address(Increment_Address),
    .Address_Accepted(Address_Accepted),
    .HTRANS(HTRANS),
    .First_Beat(First_Beat),
    .CPU_Command_Ready(CPU_Command_Ready)              // to tell the CPU i'm Ready to have a new Request
);

//Next Address Generator
Address_Generator Next_Address_Generator_Inst(
    .Current_Address(Current_Address),
    .Next_Address(Next_Address),
    .Start_Address(CPU_HADDR),
    .HBURST(HBURST_Data_Phase),
    .HSIZE(HSIZE_Data_Phase)
);

//Timeout Generator
Time_Out Timeout_Generator_Inst(
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .HREADY(HREADY),
    .TimeOut(TimeOut)
);

assign HWRITE =  HWRITE_Data_Phase;   //assign the CPU write signal to the HWRITE output
assign HADDR  = Current_Address;       //assign the current address to the HADDR output
assign HSIZE  =  HSIZE_Data_Phase;    //assign the CPU size signal to the HSIZE output
assign HBURST =  HBURST_Data_Phase;   //assign the CPU burst signal to the


//enable signal to tell CPU occure error during the transfer
                
always_ff @(posedge HCLK or negedge HRESET_n) begin 
    if (!HRESET_n) begin
        CPU_Error <= 1'b0;
    end
    else if (HRESP && HREADY) begin
        CPU_Error <= 1'b1;
    end  
end

always_ff @(posedge HCLK or negedge HRESET_n) begin
    if (!HRESET_n) begin
        Read_Valid     <= 1'b0;
        CPU_Data_Ready <= 1'b0;
    end
    else begin
        // Default values every cycle
        Read_Valid     <= 1'b0;
        CPU_Data_Ready <= 1'b0;

        if (HREADY && Address_Accepted && !TimeOut && !HRESP) begin

            if (HWRITE_Data_Phase)
                CPU_Data_Ready <= 1'b1;

            else
                Read_Valid <= 1'b1;

        end
    end
end

assign CPU_HRDATA = (Read_Valid) ? HRDATA : 'h0;    //assign the HRDATA to the CPU HHRDATA output when read valid is high, otherwise assign 0

endmodule