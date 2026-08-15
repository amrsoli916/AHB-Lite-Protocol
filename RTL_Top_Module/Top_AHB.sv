module Top_AHB #(
    parameter Data_Width = 32
) (
    ////////////////////////////////////
    //output & input from slave to peripheral
    ///////////////////////////////////
    output logic [Data_Width-1:0] P_HWDATA,
    output logic [31:0]           P_ADDR,
    output logic                  P_WRITE,
    output logic                  P_ENABLE,

    input logic [Data_Width-1:0] P_HRDATA,
    input logic                  P_READY,
    input logic                  P_ERROR,

    //////////////////////////////////////////
    //output & input from master to peripheral
    ///////////////////////////////////////////
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
    input logic [Data_Width-1:0] CPU_HWDATA,
    //Address from CPU to Master
    input logic [31:0]        CPU_HADDR,
    //output to CPU
    output logic CPU_Error ,                                //if occure error tell CPU                            
    output logic Read_Valid,                                //to tell CPU that the data is valid and ready to read
    output logic CPU_Command_Ready,
    output logic CPU_Data_Ready,                         //to tell CPU that the next burst request is enabled
    //output data to CPU
    output logic [Data_Width-1:0] CPU_HRDATA
);

///////////////////////////////////////////////////////
//Internal Signal in Top Module 
///////////////////////////////////////////////////////

logic HREADY;
logic HRESP;
logic HWRITE;
logic [Data_Width-1:0] HRDATA, HWDATA;
logic [2:0] HBURST, HSIZE;
logic [1:0] HTRANS;
logic [31:0] HADDR;
logic HSEL;
logic HREADYIN, HREADYOUT;

///////////////////////////////////////////////////////
//Instantiation the Master 
///////////////////////////////////////////////////////

Top_Master u_Master(
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .CPU_Last_Transfer(CPU_Last_Transfer),
    .CPU_HBURST(CPU_HBURST),
    .CPU_HSIZE(CPU_HSIZE),
    .CPU_Request(CPU_Request),
    .CPU_Busy(CPU_Busy),
    .CPU_HWRITE(CPU_HWRITE),
    .CPU_HWDATA(CPU_HWDATA),
    .CPU_HADDR(CPU_HADDR),
    .HREADY(HREADY),
    .HRESP(HRESP),
    .HRDATA(HRDATA),
    .HBURST(HBURST),
    .HSIZE(HSIZE),
    .HWRITE(HWRITE),
    .HTRANS(HTRANS),
    .HADDR(HADDR),
    .HWDATA(HWDATA),
    .CPU_Error(CPU_Error),
    .Read_Valid(Read_Valid),
    .CPU_Command_Ready(CPU_Command_Ready),
    .CPU_Data_Ready(CPU_Data_Ready),
    .CPU_HRDATA(CPU_HRDATA)
);


///////////////////////////////////////////////////////
//Instantiation the Slave
///////////////////////////////////////////////////////

assign HSEL = 1'b1;          //only to test this master with one slave 

AHB_Slave u_Slave(
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .HSEL(HSEL),
    .HSIZE(HSIZE),
    .HWRITE(HWRITE),
    .HTRANS(HTRANS),
    .HADDR(HADDR),
    .HREADYIN(HREADY),
    .HREADYOUT(HREADYOUT),
    .HWDATA(HWDATA),
    .HRDATA(HRDATA),
    .HRESP(HRESP),
    .P_HWDATA(P_HWDATA),
    .P_ADDR(P_ADDR),
    .P_WRITE(P_WRITE),
    .P_ENABLE(P_ENABLE),
    .P_HRDATA(P_HRDATA),
    .P_READY(P_READY),
    .P_ERROR(P_ERROR)
);

assign HREADY = HREADYOUT;
                    
endmodule