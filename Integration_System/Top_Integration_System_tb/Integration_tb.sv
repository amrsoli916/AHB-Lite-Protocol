`timescale 1ns/1ps
module Intergration_tb();
    // Defining Needed Parameters
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter PAYLOAD_BITS = 8;
    parameter CLK_HZ = 16000000;
    parameter BIT_RATE = 16000000;
    parameter FIFO_WIDTH = 8;
    parameter FIFO_DEPTH = 128;

    // Defining Input and Output Ports
    // Input Ports
    logic HCLK;
    logic HRESETn;
    logic UART_clk;
    logic PERIPH_ERROR;
    logic [PAYLOAD_BITS-1:0] DATA_DEVICE;
    // Output Ports
    logic TX_BUSY_READ;
    logic WDATA_VALID;
    logic BREAK_WRITE;
    logic BREAK_READ;
    logic [PAYLOAD_BITS-1:0] WRITTEN_DATA;
    logic FULL;
    logic EMPTY;
    // logic FORCE_WAIT;
    logic parity_out;
    logic CPU_Error;
    logic CPU_Data_Ready;

    // Instantiating the DUT
    Top_Integration #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .PAYLOAD_BITS(PAYLOAD_BITS),
        .CLK_HZ(CLK_HZ),
        .BIT_RATE(BIT_RATE),
        .FIFO_WIDTH(FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) DUT (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .UART_clk(UART_clk),
        .PERIPH_ERROR(PERIPH_ERROR),
        .DATA_DEVICE(DATA_DEVICE),
        .TX_BUSY_READ(TX_BUSY_READ),
        .WDATA_VALID(WDATA_VALID),
        .BREAK_WRITE(BREAK_WRITE),
        .BREAK_READ(BREAK_READ),
        .WRITTEN_DATA(WRITTEN_DATA),
        .FULL(FULL),
        .EMPTY(EMPTY),
        .CPU_Error(CPU_Error),
        .CPU_Data_Ready(CPU_Data_Ready),
        // .FORCE_WAIT(FORCE_WAIT),
        .parity_out(parity_out)
    );

    // Task for asserting Reset
    task assert_reset();
        HRESETn = 0;
        @(negedge HCLK);
        @(negedge UART_clk);
        HRESETn = 1;
    endtask

    // Task for checking Reset opreation
    task check_rst();
        if (DUT.HADDR !=0 || DUT.HWDATA !=0 || DUT.HWRITE !=0 
            || DUT.HBURST !=0 || DUT.HTRANS !=0) begin
                $display("Error in AHB-Reset");
                $stop;
        end
    endtask

    // Generating Randomized HRDATA
    always@(*) begin
        if(~TX_BUSY_READ) begin
            DATA_DEVICE = $random;
        end
    end

    // AHB Clock Generation
    initial begin
        HCLK = 0;
        forever begin
            #5;
            HCLK = ~HCLK;
        end
    end

    // UART Clock Generation
    initial begin
        UART_clk = 0;
        forever begin
            #31.25;
            UART_clk = ~UART_clk;
        end
    end

    // Generating Waveform for Simulator
    initial begin
        $fsdbDumpfile("system.fsdb");
        $fsdbDumpvars(0,Intergration_tb);
        $fsdbDumpMDA();
    end

    // Reading memory
    initial begin
        $readmemh("mem.dat",DUT.periph_2.SLAVE_PERIPHERAL.mem);
    end


    // SystemVerilog Assertions
    property check_htrans;
        @(posedge HCLK) disable iff (~HRESETn || ~DUT.Top_CPU_Master_int.CPU_Request) 
        $rose(DUT.Top_CPU_Master_int.CPU_Request) |=> DUT.HTRANS==2'd2; 
    endproperty

    property check_hburst;
        @(posedge HCLK) disable iff (~HRESETn || ~DUT.Top_CPU_Master_int.CPU_Request) 
        $rose(DUT.Top_CPU_Master_int.CPU_Request) |=> DUT.HBURST==2'd0;
    endproperty

    property check_hwrite_write;
        @(posedge HCLK) disable iff (~HRESETn || ~DUT.Top_CPU_Master_int.CPU_Request) 
        DUT.Top_CPU_Master_int.write |-> DUT.Top_CPU_Master_int.CPU_HWRITE;
    endproperty

    property check_hwrite_read;
        @(posedge HCLK) disable iff (~HRESETn || ~DUT.Top_CPU_Master_int.CPU_Request) 
        DUT.Top_CPU_Master_int.read |-> !DUT.Top_CPU_Master_int.CPU_HWRITE;
    endproperty

    property check_haddr;
        @(posedge HCLK) disable iff (~HRESETn || ~DUT.Top_CPU_Master_int.CPU_Request) 
        $rose(DUT.Top_CPU_Master_int.CPU_Request) |=> (DUT.HADDR===$past(DUT.Top_CPU_Master_int.CPU_TOP_Int.mem_addr));
    endproperty

    property check_wdata;
        @(posedge HCLK) disable iff (!HRESETn || DUT.Top_CPU_Master_int.read)
        DUT.HREADY && DUT.HWRITE && DUT.HTRANS == 2'd2 |=> (DUT.HWDATA == $past(DUT.Top_CPU_Master_int.CPU_HWDATA));
    endproperty

    property check_hsize;
        @(posedge HCLK) disable iff (~HRESETn || ~DUT.Top_CPU_Master_int.CPU_Request)
        $rose(DUT.Top_CPU_Master_int.CPU_Request) |=> (DUT.HSIZE == DUT.Top_CPU_Master_int.CPU_HSIZE);
    endproperty

    property check_data_out;
        @(posedge UART_clk) disable iff(~HRESETn)
        $rose(WDATA_VALID) |=> (WRITTEN_DATA == $past(DUT.UART_SLAVE_INTERFACE_int.write_data_uart));
    endproperty

    property check_rdata;
        @(posedge UART_clk) disable iff(~HRESETn)
        $rose(DUT.UART_SLAVE_INTERFACE_int.rdata_valid) |=> ##1 (DUT.UART_SLAVE_INTERFACE_int.read_data_slave[7:0] ==DUT.UART_SLAVE_INTERFACE_int.read_data_uart );
    endproperty

    // Concurrent Assertions
    //assert_check_htrans      :assert property (check_htrans)          else $error("There is a Problem in HTRANS");
    //assert_check_hburst      :assert property (check_hburst)          else $error("There is a Problem in HBURST ");
    //assert_check_hwrite_W    :assert property (check_hwrite_write)    else $error("There is a Problem in HWRITE-W");
    //assert_check_hwrite_r    :assert property (check_hwrite_read)     else $error("There is a Problem in HWRITE-R");
    //assert_check_haddr       :assert property (check_haddr)           else $error("There is a Problem in HADDR");
    //assert_check_wdata       :assert property (check_wdata)           else $error("There is a Problem in HWDATA");
    //assert_check_hsize       :assert property (check_hsize)           else $error("There is a Problem in HSIZE");
    //assert_check_data_out    :assert property (check_data_out)        else $error("There is a Problem in Written data");
    //assert_check_rdata       :assert property (check_rdata)           else $error("There is a Problem in HRDATA");


    // Covering Assertions
    //cover_check_htrans      :cover property (check_htrans);
    // cover_check_hburst      :cover property (check_hburst);
    // cover_check_hwrite_W    :cover property (check_hwrite_write);
    // cover_check_hwrite_r    :cover property (check_hwrite_read);
    // cover_check_haddr       :cover property (check_haddr);
    // cover_check_wdata       :cover property (check_wdata);
    // cover_check_hsize       :cover property (check_hsize);
    // cover_check_data_out    :cover property (check_data_out);
    // cover_check_rdata       :cover property (check_rdata);

    // Generating Testcases
    initial begin
        // Testcase 1
        PERIPH_ERROR = 0;
        // FORCE_WAIT   = 0;
        DATA_DEVICE  = 0;
        assert_reset();
        check_rst();
        // ADD TIME HERE // IMMMMMP
        repeat(300) begin
            @(negedge UART_clk);
        end
        $stop;
    end
endmodule