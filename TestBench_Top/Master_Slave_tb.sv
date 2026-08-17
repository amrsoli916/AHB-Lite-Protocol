module Master_Slave_tb ;

    parameter Data_Width = 32;

    ////////////////////////////////////
    //output & input from slave to peripheral
    ///////////////////////////////////
    logic [Data_Width-1:0] P_HWDATA;
    logic [31:0]           P_ADDR;
    logic                  P_WRITE;
    logic                  P_ENABLE;

    logic [Data_Width-1:0] P_HRDATA;
    logic                  P_READY;
    logic                  P_ERROR;

    //////////////////////////////////////////
    //output & input from master to peripheral
    ///////////////////////////////////////////
    logic HCLK;
    logic HRESET_n;

    //from CPU
    logic             CPU_Last_Transfer;
    logic [2:0]       CPU_HBURST;
    logic [2:0]       CPU_HSIZE;
    logic             CPU_Request;
    logic             CPU_Busy;
    logic             CPU_HWRITE;
    //data from CPU to Master
    logic [Data_Width-1:0] CPU_HWDATA;
    //Address from CPU to Master
    logic [31:0]        CPU_HADDR;
    //to CPU
    logic CPU_Error ;                                //if occure error tell CPU                            
    logic Read_Valid;                                //to tell CPU that the data is valid and ready to read
    logic CPU_Command_Ready;
    logic CPU_Data_Ready;                         //to tell CPU that the next burst request is enabled
    //data to CPU
    logic [Data_Width-1:0] CPU_HRDATA;

    //==================================================
    // Simple Peripheral Memory Model
    //==================================================
    logic [31:0] Peripheral_Memory [0:255] = '{default: '0};

    //==================================================
    // DUT
    //==================================================
    Top_AHB #(
        .Data_Width(Data_Width)
    ) DUT (
        .P_HWDATA(P_HWDATA),
        .P_ADDR(P_ADDR),
        .P_WRITE(P_WRITE),
        .P_ENABLE(P_ENABLE),

        .P_HRDATA(P_HRDATA),
        .P_READY(P_READY),
        .P_ERROR(P_ERROR),

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

        .CPU_Error(CPU_Error),
        .Read_Valid(Read_Valid),
        .CPU_Command_Ready(CPU_Command_Ready),
        .CPU_Data_Ready(CPU_Data_Ready),
        .CPU_HRDATA(CPU_HRDATA)
    );  

    //==================================================
    // Clock Generation
    //================================================== 
    initial begin
        HCLK = 1'b0;
        forever begin
            #5 HCLK = ~HCLK;
        end
    end   

    //==================================================
    // Peripheral Default Assignments
    //================================================== 
    assign P_READY = 1'b1;   
    assign P_ERROR = 1'b0;

    //Read From Memory
    always_comb begin 
        if(P_ENABLE && !P_WRITE)
           P_HRDATA =  Peripheral_Memory[P_ADDR[9:2]];
        else
            P_HRDATA = '0;
    end
    
    //Write on Peripheral Memory
    always_ff @(posedge HCLK) begin : blockName
        if (P_ENABLE && P_WRITE) begin
            Peripheral_Memory[P_ADDR[9:2]] <= P_HWDATA;

        $display("[Peripheral Write] time = %t Addr = %h Data = %h",
                    $time, P_ADDR, P_HWDATA);
        end
    end


    //==================================================
    // Reset
    //================================================== 
    task automatic Reset_DUT;
        begin
            HRESET_n = 1'b0;
            CPU_Last_Transfer = 1'b0;
            CPU_HBURST        = 3'b000;
            CPU_HSIZE         = 3'b010;
            CPU_Request       = 1'b0;
            CPU_Busy          = 1'b0;
            CPU_HWRITE        = 1'b0;
            CPU_HWDATA        = '0;
            CPU_HADDR         = '0;
            repeat(3) @(negedge HCLK);
            HRESET_n = 1'b1;
            @(negedge HCLK);
        end
    endtask 

    //==================================================
    // Single Write
    //================================================== 
    task automatic Single_Write(
        input logic [31:0] ADDR,
        input logic [Data_Width-1:0] DATA
        );
        begin
            $display("--------------------------------------");
            $display("START SINGLE WRITE");
            $display("ADDR = %h DATA = %h", ADDR, DATA);
            $display("--------------------------------------");

            @(negedge HCLK);
            CPU_HADDR  <= ADDR;
            CPU_HWDATA <= DATA;
            CPU_HWRITE <= 1'b1;
            CPU_HBURST <= 3'b000;
            CPU_Last_Transfer <= 1'b1;
            CPU_Request <= 1'b1;

            @(negedge HCLK);
            CPU_Request <= 1'b0;
            wait (CPU_Command_Ready == 1'b1);
            @(posedge HCLK);
            @(posedge HCLK);

            @(negedge HCLK);

            CPU_HWRITE        <= 1'b0;
            CPU_Last_Transfer <= 1'b0;
            CPU_HADDR         <= '0;
            CPU_HWDATA        <= '0;
            if (Peripheral_Memory[ADDR[9:2]] == DATA)
                $display("PASS: WRITE DATA IS CORRECT");
            else
                $display(
                    "FAIL: WRITE DATA = %h",
                    Peripheral_Memory[ADDR[9:2]]
                );
        end   
    endtask     
    
    //==================================================
    // Single Read
    //================================================== 
    task automatic Single_Read(
            input logic [31:0] ADDR
        );
        begin
            $display("--------------------------------------");
            $display("START SINGLE READ");
            $display("ADDR = %h", ADDR);
            $display("--------------------------------------");

            @(negedge HCLK);
            CPU_HADDR <= ADDR;
            CPU_HWRITE <= 1'b0;
            CPU_HBURST <= 3'b000;
            CPU_Last_Transfer <= 1'b1;
            CPU_Request <= 1'b1;

            @(negedge HCLK);
            CPU_Request <= 1'b0;
            wait(Read_Valid == 1'b1);

            if (CPU_HRDATA == 32'h1234_5678)
                $display("PASS: READ DATA IS CORRECT");
            else
                $display(
                    "FAIL: READ DATA = %h",
                    CPU_HRDATA
                );

            @(negedge HCLK);

            CPU_Last_Transfer <= 1'b0;
            CPU_HADDR         <= '0;
        end
    endtask 

    //==================================================
    // INCR4 Write
    //==================================================
    task automatic INC4_Write(
            input logic [31:0] Start_ADDR
        );

        logic [31:0] Data [0:3];
        int i;

        begin
            Data[0] = 32'h1111_1111;
            Data[1] = 32'h2222_2222;
            Data[2] = 32'h3333_3333;
            Data[3] = 32'h4444_4444;

            $display("");
            $display("======================================");
            $display("START INCR4 WRITE");
            $display("START ADDRESS = %h", Start_ADDR);
            $display("======================================");

            @(negedge HCLK);
            CPU_HADDR         <= Start_ADDR;
            CPU_HWDATA        <= Data[0];
            CPU_HWRITE        <= 1'b1;
            CPU_HBURST        <= 3'b011;       // INCR4
            CPU_HSIZE         <= 3'b010;       // WORD
            CPU_Last_Transfer <= 1'b0;
            CPU_Request       <= 1'b1;

            @(negedge HCLK);
            CPU_Request <= 1'b0;

            $display(
                "BEAT 0 : ADDR=%h DATA=%h",
                Start_ADDR,
                Data[0]
            );

            for (i = 1; i < 4; i++) begin
                @(negedge HCLK);
                while (CPU_Data_Ready !== 1'b1) begin
                    @(negedge HCLK);
                end

                CPU_HWDATA <= Data[i];

                if (i == 3)
                    CPU_Last_Transfer <= 1'b1;
                else
                    CPU_Last_Transfer <= 1'b0;

                $display(
                    "DATA %0d PREPARED = %h",
                    i,
                    Data[i]
                );
            end

            wait(CPU_Command_Ready == 1'b1);
            @(posedge HCLK);
            @(posedge HCLK);
            @(negedge HCLK);

            $display("");
            $display("----------- INCR4 WRITE CHECK -----------");

            for (i = 0; i < 4; i++) begin
                if (Peripheral_Memory[Start_ADDR[9:2] + i] === Data[i]) begin
                    $display(
                        "PASS: BEAT %0d | ADDR=%h | DATA=%h",
                        i,
                        Start_ADDR + (i * 32'd4),
                        Peripheral_Memory[Start_ADDR[9:2] + i]
                    );
                end
                else begin
                    $display(
                        "FAIL: BEAT %0d | ADDR=%h | EXPECTED=%h | ACTUAL=%h",
                        i,
                        Start_ADDR + (i * 32'd4),
                        Data[i],
                        Peripheral_Memory[Start_ADDR[9:2] + i]
                    );
                end
            end

            CPU_HWRITE        <= 1'b0;
            CPU_Last_Transfer <= 1'b0;
            CPU_HADDR         <= '0;
            CPU_HWDATA        <= '0;
            CPU_HBURST        <= 3'b000;

            @(posedge HCLK);
            $display("======================================");
            $display("INCR4 WRITE FINISHED");
            $display("======================================");
            $display("");
        end
    endtask 

    //==================================================
    // INCR4 Read
    //================================================== 
    task automatic INCR4_Read(
            input logic [31:0] Start_Address
        );
        logic [31:0] Expected [0:3];
        int i;
        Expected[0] = 32'h1111_1111;
        Expected[1] = 32'h2222_2222;
        Expected[2] = 32'h3333_3333;
        Expected[3] = 32'h4444_4444;

        @(negedge HCLK);
        CPU_HADDR         <= Start_Address;
        CPU_HWRITE        <= 1'b0;
        CPU_HBURST        <= 3'b011;       // INCR4
        CPU_HSIZE         <= 3'b010;       // 32-bit WORD
        CPU_Last_Transfer <= 1'b0;
        CPU_Request       <= 1'b1;

        @(negedge HCLK);
        CPU_Request <= 1'b0;

        for (i = 0; i < 4; i++) begin
            if (i == 3) begin
                CPU_Last_Transfer <= 1'b1;
            end

            @(negedge HCLK);
            while (Read_Valid !== 1'b1)
                @(negedge HCLK);

            if (CPU_HRDATA === Expected[i]) begin
                $display(
                    "PASS: READ BEAT %0d | ADDR=%h | DATA=%h",
                    i,
                    Start_Address + (i * 32'd4),
                    CPU_HRDATA
                );
            end
            else begin
                $display(
                    "FAIL: READ BEAT %0d | ADDR=%h | EXPECTED=%h | ACTUAL=%h",
                    i,
                    Start_Address + (i * 32'd4),
                    Expected[i],
                    CPU_HRDATA
                );
            end
        end

        CPU_Last_Transfer <= 1'b0;
        CPU_HADDR         <= '0;
        CPU_HBURST        <= 3'b000;
        @(posedge HCLK);
    endtask 

    //==================================================
    // Back-to-Back (Write then Read)
    //================================================== 
    task automatic B2B_Write_Read(
        input logic [31:0] ADDR,
        input logic [Data_Width-1:0] DATA
        );
            begin
                $display("");
                $display("======================================");
                $display("START BACK-TO-BACK WRITE & READ");
                $display("ADDR = %h DATA = %h", ADDR, DATA);
                $display("======================================");

                // 1. Issue Write Request
                @(negedge HCLK);
                CPU_HADDR         <= ADDR;
                CPU_HWDATA        <= DATA;
                CPU_HWRITE        <= 1'b1;     // Write Action
                CPU_HBURST        <= 3'b000;   // Single Transfer
                CPU_Last_Transfer <= 1'b1;
                CPU_Request       <= 1'b1;

                // Wait until Master is ready to accept a new command (Address Phase Done)
                @(negedge HCLK);
                while (CPU_Command_Ready !== 1'b1) begin
                    @(negedge HCLK);
                end

                // 2. Issue Read Request IMMEDIATELY (Zero Idle)
                // Notice we DO NOT drop CPU_Request. We change to Read instantly.
                CPU_HADDR  <= ADDR;
                CPU_HWRITE <= 1'b0; // Change to Read Action

                @(negedge HCLK);
                CPU_Request <= 1'b0; // Now we can drop the request

                // Wait for the Read command to be accepted
                while (CPU_Command_Ready !== 1'b1) begin
                    @(negedge HCLK);
                end

                // 3. Verify Write Data in Memory
                // Give Memory 1 clock cycle to commit the write data at posedge
                @(posedge HCLK);
                @(negedge HCLK);
                
                if (Peripheral_Memory[ADDR[9:2]] == DATA)
                    $display("PASS: B2B WRITE DATA IS CORRECT");
                else
                    $display("FAIL: B2B WRITE DATA = %h | EXPECTED=%h", Peripheral_Memory[ADDR[9:2]], DATA);

                // 4. Verify Read Data from CPU
                while (Read_Valid !== 1'b1) begin
                    @(negedge HCLK);
                end

                if (CPU_HRDATA === DATA)
                    $display("PASS: B2B READ DATA IS CORRECT");
                else
                    $display("FAIL: B2B READ DATA = %h | EXPECTED=%h", CPU_HRDATA, DATA);

                // Clean up
                @(negedge HCLK);
                CPU_Last_Transfer <= 1'b0;
                CPU_HADDR         <= '0;
                
                $display("======================================");
                $display("BACK-TO-BACK TEST FINISHED");
                $display("======================================");
                $display("");
            end
    endtask 

    //==================================================
    // Back-to-Back (Write then Read) WITH WAIT STATES
    //================================================== 
    task automatic B2B_Write_Read_Wait(
            input logic [31:0] ADDR_W,
            input logic [Data_Width-1:0] DATA_W,
            input logic [31:0] ADDR_R
        );
            begin
                $display("");
                $display("======================================");
                $display("START B2B WRITE & READ WITH 2 WAIT CYCLES");
                $display("WRITE ADDR = %h | READ ADDR = %h", ADDR_W, ADDR_R);
                $display("======================================");

                // 1. Issue Write Request
                @(negedge HCLK);
                CPU_HADDR         <= ADDR_W;
                CPU_HWDATA        <= DATA_W;
                CPU_HWRITE        <= 1'b1;     // Write Action
                CPU_HBURST        <= 3'b000;   // Single Transfer
                CPU_Last_Transfer <= 1'b1;
                CPU_Request       <= 1'b1;

                // Wait until Master is ready to accept a new command (Address Phase Done)
                @(negedge HCLK);
                while (CPU_Command_Ready !== 1'b1) begin
                    @(negedge HCLK);
                end

                // 2. Issue Read Request IMMEDIATELY & INJECT STALL
                CPU_HADDR  <= ADDR_R;
                CPU_HWRITE <= 1'b0; // Change to Read Action
                
                force P_READY = 1'b0; // make the HREADY = 0

                @(negedge HCLK);
                @(negedge HCLK); // two cycle
                
                release P_READY; // make the HREADY = 1

                // Wait for the Read command to be accepted
                while (CPU_Command_Ready !== 1'b1) begin
                    @(negedge HCLK);
                end

                @(negedge HCLK);
                CPU_Request <= 1'b0; 

                // 4. Verify Read Data from CPU
                while (Read_Valid !== 1'b1) begin
                    @(negedge HCLK);
                end

                // 3. Verify Write Data in Memory
                @(posedge HCLK);
                @(posedge HCLK);
                @(negedge HCLK);

                if (CPU_HRDATA == 32'h0000_0000)
                    $display("PASS: B2B WAIT - READ DATA IS CORRECT");
                else
                    $display("FAIL: B2B WAIT - READ DATA = %h | EXPECTED=0000_0000", CPU_HRDATA);

                
                if (Peripheral_Memory[ADDR_W[9:2]] == DATA_W)
                    $display("PASS: B2B WAIT - WRITE DATA IS CORRECT");
                else
                    $display("FAIL: B2B WAIT - WRITE DATA = %h | EXPECTED=%h", Peripheral_Memory[ADDR_W[9:2]], DATA_W);

                // Clean up
                @(negedge HCLK);
                CPU_Last_Transfer <= 1'b0;
                CPU_HADDR         <= '0;
                
                $display("======================================");
                $display("B2B WITH WAIT STATES TEST FINISHED");
                $display("======================================");
                $display("");
            end
    endtask

    //==================================================
    // Back-to-Back (Write then Write) WITH WAIT STATES
    //================================================== 
    task automatic B2B_Write_Write_Wait(
            input logic [31:0] ADDR_W1,
            input logic [Data_Width-1:0] DATA_W1,
            input logic [31:0] ADDR_W2,
            input logic [Data_Width-1:0] DATA_W2
        );
            begin
                $display("");
                $display("======================================");
                $display("START B2B WRITE-WRITE WITH 2 WAIT CYCLES");
                $display("WRITE 1: ADDR = %h | DATA = %h", ADDR_W1, DATA_W1);
                $display("WRITE 2: ADDR = %h | DATA = %h", ADDR_W2, DATA_W2);
                $display("======================================");

                //==================================================
                // 1. Issue First Write Request
                //==================================================
                @(negedge HCLK);
                CPU_HADDR         <= ADDR_W1;
                CPU_HWDATA        <= DATA_W1;  // Set the first data here
                CPU_HWRITE        <= 1'b1;     // Write Action
                CPU_HBURST        <= 3'b000;   // Single Transfer
                CPU_Last_Transfer <= 1'b1;
                CPU_Request       <= 1'b1;

                // Wait until Master accepts the first command (Address Phase 1 Done)
                @(negedge HCLK);
                CPU_Request <= 1'b0;
                while (CPU_Command_Ready !== 1'b1) begin
                    @(negedge HCLK);
                end

                //==================================================
                // 2. Issue Second Address ONLY & INJECT STALL
                //==================================================
                // Note: Do NOT change CPU_HWDATA yet. It must hold DATA_W1.
                CPU_Request <= 1'b1;
                CPU_HADDR  <= ADDR_W2;
                CPU_HWRITE <= 1'b1;    
                
                // Force stall (Wait States)
                force P_READY = 1'b0; 

                // Stall for 2 cycles
                @(negedge HCLK);
                @(negedge HCLK); 
                
                // Release the bus
                release P_READY; 

                //==================================================
                // 3. Wait for CPU_Data_Ready before updating to Second Data
                //==================================================
                while (CPU_Data_Ready !== 1'b1) begin
                    @(negedge HCLK);
                end
                
                // Master is ready for data; update immediately
                CPU_HWDATA <= DATA_W2; 

                // Drop request
                @(negedge HCLK);
                CPU_Request <= 1'b0; 

                // Wait for the second Write command to be accepted
                while (CPU_Command_Ready !== 1'b1) begin
                    @(negedge HCLK);
                end

                //==================================================
                // 4. Wait for Pipelined Data Phases to Finish
                //==================================================
                @(posedge HCLK);
                @(posedge HCLK);
                @(negedge HCLK);
                
                //==================================================
                // 5. Verify Write Data in Memory for BOTH Writes
                //==================================================
                if (Peripheral_Memory[ADDR_W1[9:2]] == DATA_W1)
                    $display("PASS: B2B WAIT - WRITE 1 DATA IS CORRECT (%h)", DATA_W1);
                else
                    $display("FAIL: B2B WAIT - WRITE 1 DATA = %h | EXPECTED=%h", Peripheral_Memory[ADDR_W1[9:2]], DATA_W1);

                if (Peripheral_Memory[ADDR_W2[9:2]] == DATA_W2)
                    $display("PASS: B2B WAIT - WRITE 2 DATA IS CORRECT (%h)", DATA_W2);
                else
                    $display("FAIL: B2B WAIT - WRITE 2 DATA = %h | EXPECTED=%h", Peripheral_Memory[ADDR_W2[9:2]], DATA_W2);

                //==================================================
                // 6. Clean up
                //==================================================
                @(negedge HCLK);
                CPU_Last_Transfer <= 1'b0;
                CPU_HADDR         <= '0;
                CPU_HWDATA        <= '0;
                
                $display("======================================");
                $display("B2B WRITE-WRITE WITH WAIT STATES FINISHED");
                $display("======================================");
                $display("");
            end
    endtask

    //==================================================
    // INCR4 Error Test (Error after 1st Beat)
    //================================================== 
    task automatic INCR4_Error_Test(
        input logic [31:0] Start_ADDR
        );
        logic [31:0] Data [0:3];
        begin
            Data[0] = 32'hA1A1_A1A1;
            Data[1] = 32'hB2B2_B2B2;
            Data[2] = 32'hC3C3_C3C3;
            Data[3] = 32'hD4D4_D4D4;

            $display("");
            $display("======================================");
            $display("START INCR4 ERROR TEST (Error on 2nd Beat)");
            $display("START ADDRESS = %h", Start_ADDR);
            $display("======================================");

            //==================================================
            // 1. Start Beat 0 (First Transfer - Normal)
            //==================================================
            @(negedge HCLK);
            CPU_HADDR         <= Start_ADDR;
            CPU_HWDATA        <= Data[0];
            CPU_HWRITE        <= 1'b1;
            CPU_HBURST        <= 3'b011;       // INCR4
            CPU_HSIZE         <= 3'b010;       // WORD
            CPU_Last_Transfer <= 1'b0;
            CPU_Request       <= 1'b1;

            @(negedge HCLK);
            CPU_Request <= 1'b0;

            while (CPU_Data_Ready !== 1'b1) @(negedge HCLK);
            
            //==================================================
            // 2. Start Beat 1 (Second Transfer - Will have Error)
            //==================================================
            // first data
            CPU_HWDATA <= Data[1];
            
            @(negedge HCLK);
            while (CPU_Data_Ready !== 1'b1) @(negedge HCLK);
            
            //==================================================
            // 3. Inject Error during Beat 1 Data Phase
            //==================================================
            
            CPU_HWDATA <= Data[2]; // المعالج يضع بيانات النبضة الثالثة كالمعتاد
            
            // 😈 حقن الخطأ بقوة!
            $display("--- Injecting P_ERROR = 1 during Beat 1 ---");
            force P_ERROR = 1'b1;

            //==================================================
            // 4. Check Master Reaction
            //==================================================
            // ننتظر دورة أو دورتين لنرى هل سيرفع الـ Master إشارة CPU_Error
            @(negedge HCLK);
            if (CPU_Error !== 1'b1) @(negedge HCLK);
            
            if (CPU_Error === 1'b1)
                $display("PASS: MASTER ABORTED BURST AND DETECTED ERROR (CPU_Error = 1)");
            else
                $display("FAIL: MASTER IGNORED BURST ERROR (CPU_Error = 0)");

            //==================================================
            // 5. Clean up & Abort from CPU side
            //==================================================
            // إطلاق سراح إشارة الخطأ لتعود لطبيعتها
            release P_ERROR;
            
            // المعالج (CPU) يُلغي باقي الـ Burst بمجرد رؤيته للخطأ
            @(negedge HCLK);
            CPU_HWRITE        <= 1'b0;
            CPU_Last_Transfer <= 1'b0;
            CPU_HADDR         <= '0;
            CPU_HWDATA        <= '0;
            CPU_HBURST        <= 3'b000;
            
            // نعطي الـ Master بعض الدورات الزمنية ليعود إلى حالة الـ IDLE بأمان
            repeat(3) @(posedge HCLK);

            $display("======================================");
            $display("INCR4 ERROR TEST FINISHED");
            $display("======================================");
            $display("");
        end
    endtask

    //==================================================
    // Test Initial Block
    //==================================================
    initial begin
        
        Reset_DUT();

        //==================================================
        // Test Write
        //==================================================
        Single_Write(
                32'h0000_0010,
                32'h1234_5678
        );

        //==================================================
        // Test Read
        //==================================================
        Single_Read(
                32'h0000_0010
            );

        //==================================================
        // Test INCR4 Write
        //==================================================
        INC4_Write(
            32'h0000_0004
        );

        //==================================================
        // Test INCR4 Read
        //==================================================
        INCR4_Read(
            32'h0000_0004
        );

        //==================================================
        // Test Back-to-Back (Write -> Read)
        //==================================================
        B2B_Write_Read(
            32'h0000_0020,
            32'hAAAA_BBBB
        );

        //==================================================
        // Test Back-to-Back (Write -> Read) with Wait States
        //==================================================
        B2B_Write_Read_Wait(
            32'h0000_0030, // Address Write
            32'hCCCC_DDDD, // Data Write
            32'h0000_0020  // Address Read
        );

        //==================================================
        // Test Back-to-Back (Write -> Write) with Wait States
        //==================================================
        B2B_Write_Write_Wait(
            32'h0000_0070, // Address Write 1
            32'h1122_3344, // Data Write 1
            32'h0000_0080, // Address Write 2
            32'h5566_7788  // Data Write 2
        );

        //==================================================
        // Test Error Response
        //==================================================
        INCR4_Error_Test(
            32'h0000_0060
        );

        #20;
        $display("--------------------------------------");
        $display("TEST FINISHED");
        $display("--------------------------------------");

        $stop;
    end

    //==================================================
    // Waveform Dump
    //==================================================
    initial begin
        // 1. Specify the name of the output waveform file
        $fsdbDumpfile("waves.fsdb"); 
        
        // 2. Dump all variables in the current module (Master_tb) and below (level 0)
        $fsdbDumpvars(0, Master_Slave_tb); 
        
        // 3. Dump Multi-Dimensional Arrays (CRITICAL to see the 'Memory' array in Verdi)
        $fsdbDumpMDA(); 

    end
endmodule