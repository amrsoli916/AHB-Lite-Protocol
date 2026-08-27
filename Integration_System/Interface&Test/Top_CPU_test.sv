`timescale 1ns/1ps

module CPU_Master_tb ();

    logic HCLK;
    logic HRESET_n;
 
    logic [2:0] HBURST;
    logic [2:0] HSIZE;
    logic       HWRITE;
    logic [1:0] HTRANS;
    logic [31:0] HADDR;
    logic [31:0] HWDATA;
    
    logic HREADY;
    logic HRESP;
    
    // data from slave to Master 
    logic [31:0] HRDATA;

    // to debug the code 
    logic CPU_Error;
    logic CPU_Data_Ready;

    Top_CPU_Master DUT_Master_tb(
        .HCLK(HCLK), .HRESET_n(HRESET_n), .HBURST(HBURST), .HSIZE(HSIZE),
        .HWRITE(HWRITE), .HTRANS(HTRANS), .HADDR(HADDR), .HWDATA(HWDATA),
        .HREADY(HREADY), .HRESP(HRESP), .HRDATA(HRDATA),
        .CPU_Error(CPU_Error), .CPU_Data_Ready(CPU_Data_Ready)
    );

    // Generate the clk
    initial begin
        HCLK = 0;
        forever begin
            #5 HCLK = ~HCLK;
        end
    end

    //-----------------------------------------------------
    // Reset + Default Slave Response
    //-----------------------------------------------------
    initial begin
        HRESET_n = 0;
        HREADY = 1'b1;
        HRESP  = 1'b0;

        // Returned data for load operations
        
        HRDATA = 32'h12345678;

        repeat(5) @(posedge HCLK);

        HRESET_n = 1;
    end

    //-----------------------------------------------------
    // Insert Wait State
    // Test the Pipeline Stall (HREADY = 0)
    //-----------------------------------------------------
    // initial begin
    //     wait(HRESET_n);
        
        
    //     wait(HTRANS == 2'b10); 

    //     @(posedge HCLK);

    //     $display("----- Wait State Started -----");
    //     HREADY = 1'b0; 

        
    //     repeat(4) @(posedge HCLK);

    //     HREADY = 1'b1; 
    //     $display("----- Wait State Finished -----");
    // end

    //-----------------------------------------------------
    // FSDB Dump for Verdi
    //-----------------------------------------------------
    initial begin
        $fsdbDumpfile("CPU_AHB.fsdb");
        $fsdbDumpvars(0, CPU_Master_tb);
        $fsdbDumpMDA();
    end

    //-----------------------------------------------------
    // Stop Simulation
    //-----------------------------------------------------
    initial begin
        #1000; 
        $stop;
    end
    
endmodule