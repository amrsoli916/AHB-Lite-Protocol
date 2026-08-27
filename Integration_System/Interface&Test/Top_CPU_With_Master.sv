module Top_CPU_Master(
    //clock and reset
    input logic HCLK,
    input logic HRESET_n,

    //Output to Slave
    output logic [2:0] HBURST,
    output logic [2:0] HSIZE,
    output logic       HWRITE,
    output logic [1:0] HTRANS,
    //Address to Slave 
    output logic [31:0] HADDR,
    //Data output to slave 
    output logic [31:0] HWDATA,

    //input from slave 
    input logic HREADY,
    input logic HRESP,
    //data from slave to Master 
    input logic [31:0] HRDATA, 

    //output to debugg the code 
    output logic CPU_Error,
    output logic CPU_Data_Ready
);

logic        CPU_Last_Transfer;
logic [2:0]  CPU_HBURST;
logic [2:0]  CPU_HSIZE;
logic        CPU_Request;
logic        CPU_HWRITE;
logic [31:0] CPU_HADDR;
logic        Read_Valid;
logic        CPU_Command_Ready;
logic [31:0] CPU_HRDATA;
logic        write, read, size;

logic [31:0] MIPS_Raw_Write_Data;
logic [31:0] CPU_HWDATA;
logic        CPU_Stall;

assign CPU_Stall = (write && !CPU_Command_Ready) || (read && !Read_Valid);

always_ff @(posedge HCLK or negedge HRESET_n) begin 
    if (!HRESET_n) begin
        CPU_HWDATA <= 32'b0;
    end
    else if (!CPU_Stall) begin
        CPU_HWDATA <= MIPS_Raw_Write_Data;
    end
end

TOP_Pip_MIPS CPU_TOP_Int(                                     //instantation the top od CPU
    .clk(HCLK), .reset(~HRESET_n), .mem_addr(CPU_HADDR), .mem_write_data(MIPS_Raw_Write_Data), 
    .mem_read_data(CPU_HRDATA), .CPU_Command_Ready(CPU_Command_Ready), .Read_Valid(Read_Valid),
    .mem_write_en(write), .mem_read_en(read), .output_size(size)
);

assign CPU_HWRITE = write;

assign CPU_HSIZE = (size)? 3'b000 : 3'b010;

assign CPU_HBURST = 3'b000;

assign CPU_Request = (write || read);


Top_Master Top_Master_int(                                  //instantiation the Top_Master
    .HCLK(HCLK), .HRESET_n(HRESET_n), .CPU_Last_Transfer(1'b1), .CPU_HBURST(CPU_HBURST),
    .CPU_HSIZE(CPU_HSIZE), .CPU_Request(CPU_Request), .CPU_Busy(1'b0), .CPU_HWRITE(CPU_HWRITE),
    .CPU_HWDATA(CPU_HWDATA), .CPU_HADDR(CPU_HADDR), .HREADY(HREADY), .HRESP(HRESP), .HRDATA(HRDATA), 
    .HBURST(HBURST), .HSIZE(HSIZE), .HWRITE(HWRITE), .HTRANS(HTRANS), .HADDR(HADDR), .HWDATA(HWDATA),
    .CPU_Error(CPU_Error), .Read_Valid(Read_Valid), .CPU_Command_Ready(CPU_Command_Ready),
    .CPU_Data_Ready(CPU_Data_Ready), .CPU_HRDATA(CPU_HRDATA)
);

endmodule