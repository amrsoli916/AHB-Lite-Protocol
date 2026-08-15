module AHB_Slave #(
    parameter Data_Width = 32
)(
    input logic HRESET_n,
    input logic HCLK,

    ////////////////////////////
    //AHB Input
    ///////////////////////////
    input logic                  HSEL,
    input logic [2:0]            HSIZE ,
    input logic                  HWRITE,
    input logic [1:0]            HTRANS,
    input logic [31:0]           HADDR,
    input logic                  HREADYIN,
    input logic [Data_Width-1:0] HWDATA,

    /////////////////////////////
    //AHB Output
    /////////////////////////////
    output logic HREADYOUT,
    output logic HRESP,
    output logic [Data_Width-1:0] HRDATA,

    /////////////////////////////
    //Peripheral Interface
    ////////////////////////////
    output logic [Data_Width-1:0] P_HWDATA,
    output logic [31:0]           P_ADDR,
    output logic                  P_WRITE,
    output logic                  P_ENABLE,

    input logic [Data_Width-1:0] P_HRDATA,
    input logic                  P_READY,
    input logic                  P_ERROR
);

localparam logic [1:0] HTRANS_IDLE   = 2'b00;
localparam logic [1:0] HTRANS_BUSY   = 2'b01;
localparam logic [1:0] HTRANS_NONSEQ = 2'b10;
localparam logic [1:0] HTRANS_SEQ    = 2'b11;

logic Capture_Address_Enable;
logic Data_Phase_Valid;
logic [2:0] HSIZE_reg;
logic HWRITE_reg;
logic [31:0] HADDR_reg;
logic Error_Complete;

assign Capture_Address_Enable = HSEL &&
                HREADYIN && 
            (HTRANS inside {HTRANS_NONSEQ, HTRANS_SEQ});

//Captur the information signal to the data get in the second cycle
always_ff @(posedge HCLK or negedge HRESET_n ) begin 
    if (!HRESET_n) begin
        HSIZE_reg  <= '0;
        HWRITE_reg <= 1'b0;
        HADDR_reg  <= '0;
    end
    else if (Capture_Address_Enable) begin
        HSIZE_reg  <= HSIZE;
        HWRITE_reg <= HWRITE;
        HADDR_reg  <= HADDR;
    end
end

/////////////////////////////////
//Data phase valid 
////////////////////////////////
always_ff @(posedge HCLK or negedge HRESET_n) begin : blockName
    if (!HRESET_n) begin
        Data_Phase_Valid <= 0;
    end
    else if (Capture_Address_Enable) begin
        Data_Phase_Valid <= 1;          //This mean the data is True can transimitte on the Bus
    end
    else if (Data_Phase_Valid && (P_READY || Error_Complete)) begin
        Data_Phase_Valid <= 0;         //This mean I don't capture new address and the bus now ready, but the master end the Transimitte 
    end
end

////////////////////////////////
//Peripheral Data Bus
//////////////////////////////

assign P_ENABLE = Data_Phase_Valid && !Error_Complete;

assign P_ADDR = HADDR_reg;                          //Transimitte tha Address for Peripheral

assign P_WRITE = Data_Phase_Valid && HWRITE_reg;    //if this is true the data on the bus is valid to Peripheral

assign P_HWDATA = HWDATA;                           //write the data from the master on the bus to the Peripheral

/////////////////////////////////////////////
//Read data from the Peripheral to the master
/////////////////////////////////////////////

always_comb begin 
    
    HRDATA = '0;

    if(P_ENABLE && !HWRITE_reg)           //if the instruction is read & it is valid can transimitte the data to the master
        HRDATA = P_HRDATA;
end

////////////////////////////////////////
//Error Response & Wait state 
////////////////////////////////////////

Error_Response Error_Response_Inc(
    .P_ERROR(P_ERROR),
    .P_READY(P_READY),
    .HCLK(HCLK),
    .HRESET_n(HRESET_n),
    .HADDR(HADDR_reg),
    .Data_Phase_Valid(Data_Phase_Valid),
    .HREADYOUT(HREADYOUT),
    .HRESP(HRESP),
    .Error_Complete(Error_Complete)
);


endmodule