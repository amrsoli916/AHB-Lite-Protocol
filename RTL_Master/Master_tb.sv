module Master_tb;

    //Parameters
    parameter width = 32;

    //clock and reset
    logic HCLK;
    logic HRESET_n;

    //input from CPU
    logic             CPU_Last_Transfer;
    logic [2:0]       CPU_HBURST;
    logic [2:0]       CPU_HSIZE;
    logic             CPU_Request;
    logic             CPU_Busy;
    logic             CPU_HWRITE;
    //data from CPU to Master
    logic [width-1:0] CPU_HWDATA;
    //Address from CPU to Master
    logic [31:0]        CPU_HADDR;

    //input from slave 
    logic HREADY;
    logic HRESP;
    //data from slave to Master 
    logic [width-1:0] HRDATA;

    //output to Slave 
    logic [2:0] HBURST;
    logic [2:0] HSIZE;
    logic HWRITE;
    logic [1:0] HTRANS;
    //Address to Slave 
    logic [31:0] HADDR;
    //Data output to slave 
    logic [width-1:0] HWDATA;

    //output to CPU
    logic CPU_Error ;                               //if occure error tell CPU 
    logic CPU_Data_Ready;                           //if slave is ready to transimitte data tell CPU
    logic Read_Valid;                              //to tell CPU that the data is valid and ready to read
    logic CPU_Command_Ready;                         //to tell CPU that the next burst request is enabled
    //output data to CPU
    logic [width-1:0] CPU_HRDATA;

    //instantiation of Master Top
    Top_Master #(.width(width)) Master_Top_Inst(
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
        .CPU_Data_Ready(CPU_Data_Ready),
        .Read_Valid(Read_Valid),
        .CPU_Command_Ready(CPU_Command_Ready),
        .CPU_HRDATA(CPU_HRDATA)
    );

    //clock generation
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK; // 100MHz clock
    end


    //small model slave 
    logic [31:0] Memory [0:1023];
    logic        write_d;
    logic [1:0]  htrans_d;
    logic [31:0] addr_d;

    always @(posedge HCLK or negedge HRESET_n) begin
        if(!HRESET_n)begin
            write_d <= 0;
            htrans_d <= 0;
            addr_d  <= '0;
        end
        else begin
            write_d <= HWRITE;
            htrans_d <= HTRANS;
            addr_d  <= HADDR;
        end
    end

    ///////////////////////////////
    // Write In Memory (Instant Visual Update)
    //////////////////////////////
    always_comb begin
        
        if (HREADY && write_d && (htrans_d == 2'b10 || htrans_d == 2'b11)) begin
            Memory[addr_d[31:2]] = HWDATA; 
        end
        
    end

    ////////////////////////////////
    //Read From Memoty
    ////////////////////////////////
    always_comb begin

    if (HREADY && !HWRITE)
            HRDATA = Memory[addr_d[31:2]];
        else
            HRDATA = '0;

    end

    ///////////////////////////////
    //Reset
    ///////////////////////////////
    task automatic Reset();

        begin

            HRESET_n = 0;

            CPU_Request = 0;
            CPU_Busy = 0;
            CPU_HWRITE = 0;
            CPU_HADDR = 0;
            CPU_HBURST = 0;
            CPU_HSIZE = 3'b010;
            CPU_HWDATA = 0;
            CPU_Last_Transfer = 0;

            HREADY = 1;
            HRESP = 0;

            repeat(5) @(posedge HCLK);

            HRESET_n = 1;
        end
    endtask

    ////////////////////////////////////
    // Send Command (Auto-Drop Request)
    ////////////////////////////////////
    task automatic Send_Command(
            input logic [31:0] Address,
            input logic [2:0]  Burst,
            input logic [2:0]  Size,
            input logic        Write,
            input logic [31:0] Data
        );
        begin
            @(negedge HCLK);
            CPU_HADDR   <= Address;
            CPU_HBURST  <= Burst;
            CPU_HSIZE   <= Size;
            CPU_HWRITE  <= Write;
            CPU_HWDATA  <= Data;
            CPU_Request <= 1'b1;

            // 💡 Background thread: Auto-drops CPU_Request at the perfect time!
            fork
                begin
                    wait(HTRANS == 2'b10); 
                    @(negedge HCLK);
                    CPU_Request <= 1'b0;
                end
            join_none
        end
    endtask

    /////////////////////////////////////
    // Wait for Master to Accept Request 
    /////////////////////////////////////
    task automatic Wait_Command_Accepted();
        begin
            wait(HTRANS == 2'b10); 
        end
    endtask

    //////////////////////////////
    //Wait Write Accept
    /////////////////////////////
    task automatic Wait_Write_Accepted();
        begin
            @(posedge HCLK);
            
            while (CPU_Data_Ready == 1'b0) begin
                @(posedge HCLK);
            end

            @(negedge HCLK);
        end
    endtask

    ////////////////////////////////
    //Wait Read Accept
    ///////////////////////////////
    task automatic Wait_Read_Accepted();
        begin
            wait (Read_Valid == 1'b1);

            //CPU_HRDATA now Became True
            @(negedge HCLK);
        end
    endtask

    /////////////////////////////////////
    //Clear the CPU Interface
    ////////////////////////////////////
    task automatic Clear_CPU_Interface();

        begin

            @(negedge HCLK);

            CPU_Request <= 1'b0;
            CPU_HADDR   <= '0;
            CPU_HWRITE  <= 1'b0;
            CPU_HBURST  <= 3'b000;
            CPU_HSIZE   <= 3'b000;
            CPU_HWDATA  <= '0;
        end
    endtask

    //////////////////////////////
    //Single Write
    //////////////////////////////
    task automatic Single_Write();

        logic [31:0] Address;
        logic [31:0] Data;

        begin

            Address = 32'h0000_0000;
            Data    = 32'h1234_5678;

            $display("\n===== SINGLE WRITE =====");

            Send_Command(
                Address,
                3'b000,          // SINGLE
                3'b010,          // WORD
                1'b1,            // WRITE
                Data
            );

            Wait_Command_Accepted();

            CPU_HWDATA <= Data;

            Wait_Write_Accepted();

            @(posedge HCLK);

            if (Memory[Address>>2] == Data)
                $display("PASS : Single Write | Address = 0x%08h | Data = 0x%08h",
                            Address, Data);
            else begin
                $display("FAIL : Single Write");
                $display("Expected = %h", Data);
                $display("Actual   = %h", Memory[Address>>2]);
            end
            Clear_CPU_Interface();
        end
    endtask

    ///////////////////////////
    //Single Read
    //////////////////////////
    task automatic Single_Read();

            logic [31:0] Address;
            logic [31:0] Expected_Data;

        begin

            Address       = 32'h0000_0000;
            Expected_Data = 32'h1234_5678;

            // // Initialize memory
            // Memory[Address>>2] = Expected_Data;

            $display("\n===== SINGLE READ =====");

            Send_Command(
                Address,
                3'b000,          // SINGLE
                3'b010,          // WORD
                1'b0,            // READ
                32'h0
            );

            Wait_Command_Accepted();

            Wait_Read_Accepted();

            @(posedge HCLK);

            if (CPU_HRDATA == Expected_Data)
                $display("PASS : Single Read  | Address = 0x%08h | Data = 0x%08h",
                                Address, CPU_HRDATA);
            else begin
                $display("FAIL : Single Read");
                $display("Expected = %h", Expected_Data);
                $display("Actual   = %h", CPU_HRDATA);
            end
            Clear_CPU_Interface();
        end
    endtask

    /////////////////////////////////////
    // Test INCR4 Write
    /////////////////////////////////////
    task automatic INCR4_Write();

                logic [31:0] Data [0:3];
                int i;

            begin

                Data[0] = 32'h1111_1111;
                Data[1] = 32'h2222_2222;
                Data[2] = 32'h3333_3333;
                Data[3] = 32'h4444_4444;

                $display("\n========== INCR4 WRITE TEST ==========");

                //--------------------------------------------------
                // Send Command (First Data is passed to Send_Command)
                //--------------------------------------------------
                Send_Command(
                    32'h0000_0040,      // Start Address
                    3'b011,             // INCR4
                    3'b010,             // WORD
                    1'b1,               // WRITE
                    Data[0]
                );

                //--------------------------------------------------
                // Wait until Master accepts the command
                //--------------------------------------------------
                Wait_Command_Accepted();
                Wait_Write_Accepted();

                //--------------------------------------------------
                // Remaining beats
                //--------------------------------------------------
                for(i=1; i<4; i++) begin

                    CPU_HWDATA <= Data[i];
                    Wait_Write_Accepted();
                end

                @(posedge HCLK);

                //--------------------------------------------------
                // Check Memory
                //--------------------------------------------------
                if ( Memory[(32'h40>>2)+0] == Data[0] &&
                    Memory[(32'h40>>2)+1] == Data[1] &&
                    Memory[(32'h40>>2)+2] == Data[2] &&
                    Memory[(32'h40>>2)+3] == Data[3] )
                begin
                    $display("\nPASS : INCR4 WRITE");

                    for(i=0;i<4;i++) begin
                        $display("Address = %08h   Data = %08h",
                                32'h40 + (i*4),
                                Memory[(32'h40>>2)+i]);
                    end
                end
                else begin
                    $display("\nFAIL : INCR4 WRITE");

                    for(i=0;i<4;i++) begin
                        $display("Address = %08h   Expected = %08h   Actual = %08h",
                                32'h40 + (i*4),
                                Data[i],
                                Memory[(32'h40>>2)+i]);
                    end
                end

                Clear_CPU_Interface();
        end
    endtask

    //////////////////////////////
    //Test Read INCR4
    ///////////////////////////////
    task automatic INCR4_Read();

            logic [31:0] Expected [0:3];
            int i;

        begin

            Expected[0] = 32'h11111111;
            Expected[1] = 32'h22222222;
            Expected[2] = 32'h33333333;
            Expected[3] = 32'h44444444;

            // Memory[(32'h40>>2)+0] = Expected[0];
            // Memory[(32'h40>>2)+1] = Expected[1];
            // Memory[(32'h40>>2)+2] = Expected[2];
            // Memory[(32'h40>>2)+3] = Expected[3];

            $display("\n========== INCR4 READ TEST ==========");

            Send_Command(
                32'h0000_0040,
                3'b011,
                3'b010,
                1'b0,
                '0
            );

            Wait_Command_Accepted();

            for(i=0; i<4; i++) begin

                Wait_Read_Accepted();

                if (CPU_HRDATA == Expected[i])
                    $display("PASS Beat %0d : Address = 0x%08h  Data = 0x%08h",
                            i,
                            HADDR,
                            CPU_HRDATA);
                else
                    $display("FAIL Beat %0d : Address = 0x%08h  Expected = 0x%08h  Actual = 0x%08h",
                            i,
                            HADDR,
                            Expected[i],
                            CPU_HRDATA);

            end

            Clear_CPU_Interface();
        end
    endtask

    //////////////////////////////
    //Test Write Wrapping4
    /////////////////////////////
    task automatic WRAP4_Write();

            logic [31:0] Data [0:3];
            int i;

        begin

            Data[0] = 32'h1111_1111;
            Data[1] = 32'h2222_2222;
            Data[2] = 32'h3333_3333;
            Data[3] = 32'h4444_4444;

            $display("\n========== WRAP4 WRITE ==========");

            Send_Command(
                32'h0000_004C,      // Start Address
                3'b010,             // WRAP4
                3'b010,             // WORD
                1'b1,               // WRITE
                Data[0]
            );

            Wait_Command_Accepted();
            Wait_Write_Accepted();

            for(i=1;i<4;i++) begin
                CPU_HWDATA <= Data[i];
                Wait_Write_Accepted();
            end

            @(posedge HCLK);

            if ( Memory['h13] == Data[0] &&   //0x4C
                Memory['h10] == Data[1] &&   //0x40
                Memory['h11] == Data[2] &&   //0x44
                Memory['h12] == Data[3])     //0x48
            begin
                $display("PASS : WRAP4 WRITE");

                $display("0x4C = %08h",Memory['h13]);
                $display("0x40 = %08h",Memory['h10]);
                $display("0x44 = %08h",Memory['h11]);
                $display("0x48 = %08h",Memory['h12]);
            end
            else begin
                $display("FAIL : WRAP4 WRITE");
            end

            Clear_CPU_Interface();

        end
    endtask

    /////////////////////////////
    //Test Read Wrapping4
    /////////////////////////////
    task automatic WRAP4_Read();

            logic [31:0] Expected [0:3];
            logic [31:0] Read_Data [0:3];
            int i;

        begin

            Expected[0]=32'h1111_1111;
            Expected[1]=32'h2222_2222;
            Expected[2]=32'h3333_3333;
            Expected[3]=32'h4444_4444;

            // Memory['h13]=Expected[0];   //0x4C
            // Memory['h10]=Expected[1];   //0x40
            // Memory['h11]=Expected[2];   //0x44
            // Memory['h12]=Expected[3];   //0x48

            $display("\n========== WRAP4 READ ==========");

            Send_Command(
                32'h0000_004C,
                3'b010,          // WRAP4
                3'b010,
                1'b0,
                32'h0
            );

            Wait_Command_Accepted();

            for(i=0;i<4;i++) begin
                Wait_Read_Accepted();
                Read_Data[i] = CPU_HRDATA;
            end

            if(Read_Data[0]==Expected[0] &&
            Read_Data[1]==Expected[1] &&
            Read_Data[2]==Expected[2] &&
            Read_Data[3]==Expected[3]) begin

                $display("PASS : WRAP4 READ");

                $display("0x4C -> %08h",Read_Data[0]);
                $display("0x40 -> %08h",Read_Data[1]);
                $display("0x44 -> %08h",Read_Data[2]);
                $display("0x48 -> %08h",Read_Data[3]);

            end
            else begin

                $display("FAIL : WRAP4 READ");

                for(i=0;i<4;i++)
                    $display("Beat %0d Expected=%08h Actual=%08h",
                            i,Expected[i],Read_Data[i]);
            end

            Clear_CPU_Interface();

        end
    endtask

    /////////////////////////////
    // Pipelined Back-to-Back Write
    /////////////////////////////
    task automatic BackToBack_Write();
        logic [31:0] Data1 [0:3];
        logic [31:0] Data2 [0:3];
        logic pass_flag;
        int i;
        begin
            // Initialize Data
            Data1 = '{32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444};
            Data2 = '{32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 32'hDDDD_DDDD};

            $display("\n========== BACK TO BACK WRITE ==========");

            // 1. Send Burst 1 Command
            Send_Command(32'h0000_0040, 3'b011, 3'b010, 1'b1, Data1[0]);
            Wait_Command_Accepted();

            Wait_Write_Accepted(); // Beat 0
            CPU_HWDATA <= Data1[1];
            
            Wait_Write_Accepted(); // Beat 1
            CPU_HWDATA <= Data1[2];

            Wait_Write_Accepted(); // Beat 2 (Burst 1)
            
            // 2. Overlap Burst 2 Command & Burst 1's Last Data EXACTLY here
            // We are already at a negedge, so we drive immediately without waiting!
            CPU_HADDR   <= 32'h0000_0080;
            CPU_HBURST  <= 3'b011;
            CPU_HSIZE   <= 3'b010;
            CPU_HWRITE  <= 1'b1;
            CPU_Request <= 1'b1;
            
            CPU_HWDATA  <= Data1[3]; // Last beat of Burst 1

            // Background thread: Auto-drop Burst 2's Request
            fork
                begin
                    wait(HTRANS == 2'b10); 
                    @(negedge HCLK);
                    CPU_Request <= 1'b0;
                end
            join_none

            Wait_Write_Accepted(); // Beat 3 (Burst 1) - Complete

            // 3. Seamless Transition to Burst 2 Data Phase
            CPU_HWDATA <= Data2[0];
            Wait_Write_Accepted(); // Beat 0 (Burst 2)
            
            CPU_HWDATA <= Data2[1];
            Wait_Write_Accepted(); // Beat 1 (Burst 2)
            
            CPU_HWDATA <= Data2[2];
            Wait_Write_Accepted(); // Beat 2 (Burst 2)
            
            CPU_HWDATA <= Data2[3];
            Wait_Write_Accepted(); // Beat 3 (Burst 2)

            @(posedge HCLK);

            // 4. Verify Memory Array
            pass_flag = 1'b1;
            for(i=0; i<4; i++) begin
                if(Memory['h10+i] != Data1[i] || Memory['h20+i] != Data2[i]) 
                    pass_flag = 1'b0;
            end

            if (pass_flag) $display("PASS : BACK TO BACK WRITE");
            else $display("FAIL : BACK TO BACK WRITE");

            Clear_CPU_Interface();
        end
    endtask

    /////////////////////////////
    // Pipelined Back-to-Back Read
    /////////////////////////////
    task automatic BackToBack_Read();
        logic [31:0] Expected1 [0:3], Expected2 [0:3];
        logic [31:0] Read1 [0:3], Read2 [0:3];
        logic pass_flag;
        int i;
        begin
            // Initialize Memory Array
            Expected1 = '{32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444};
            Expected2 = '{32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 32'hDDDD_DDDD};
            
            // for(i=0; i<4; i++) begin
            //     Memory['h10+i] = Expected1[i];
            //     Memory['h20+i] = Expected2[i];
            // end

            $display("\n========== BACK TO BACK READ ==========");

            // 1. Send Burst 1 Command
            Send_Command(32'h0000_0040, 3'b011, 3'b010, 1'b0, 32'h0);
            Wait_Command_Accepted();

            Wait_Read_Accepted(); Read1[0] = CPU_HRDATA; // Beat 0
            Wait_Read_Accepted(); Read1[1] = CPU_HRDATA; // Beat 1
            Wait_Read_Accepted(); Read1[2] = CPU_HRDATA; // Beat 2

            // 2. Overlap Burst 2 Command EXACTLY here (at the negedge)
            CPU_HADDR   <= 32'h0000_0080;
            CPU_HBURST  <= 3'b011;
            CPU_HSIZE   <= 3'b010;
            CPU_HWRITE  <= 1'b0;
            CPU_Request <= 1'b1;

            // Background thread: Auto-drop Burst 2's Request
            fork
                begin
                    wait(HTRANS == 2'b10); 
                    @(negedge HCLK);
                    CPU_Request <= 1'b0;
                end
            join_none

            Wait_Read_Accepted(); Read1[3] = CPU_HRDATA; // Beat 3 (Burst 1 Done)

            // 3. Receive Burst 2 Data without stalling
            Wait_Read_Accepted(); Read2[0] = CPU_HRDATA; // Beat 0
            Wait_Read_Accepted(); Read2[1] = CPU_HRDATA; // Beat 1
            Wait_Read_Accepted(); Read2[2] = CPU_HRDATA; // Beat 2
            Wait_Read_Accepted(); Read2[3] = CPU_HRDATA; // Beat 3

            // 4. Verify Reads
            pass_flag = 1'b1;
            for(i=0; i<4; i++) begin
                if(Read1[i] != Expected1[i] || Read2[i] != Expected2[i]) 
                    pass_flag = 1'b0;
            end

            if(pass_flag) $display("PASS : BACK TO BACK READ");
            else $display("FAIL : BACK TO BACK READ");

            Clear_CPU_Interface();
        end
    endtask

    ////////////////////////////////////////////////////////
    // Test: Slave inserts Wait States (HREADY = 0)
    ////////////////////////////////////////////////////////
    task automatic Wait_States_Test();
        logic [31:0] Address;
        logic [31:0] Data;
        begin
            Address = 32'h0000_00A0;
            Data    = 32'h5555_5555;

            $display("\n========== WAIT STATES TEST (HREADY = 0) ==========");

            // 1. Send Command normally
            Send_Command(Address, 3'b000, 3'b010, 1'b1, Data);
            Wait_Command_Accepted();
            CPU_HWDATA <= Data;

            // 2. Simulate a slow Slave by pulling HREADY low
            @(negedge HCLK);
            HREADY = 1'b0; 
            $display("-> Slave: Injecting 3 Wait States (HREADY = 0)...");

            // Wait for 3 clock cycles
            repeat(3) @(posedge HCLK);

            // 3. Slave is finally ready
            @(negedge HCLK);
            HREADY = 1'b1; 
            $display("-> Slave: Ready! (HREADY = 1)");

            // 4. Wait for the Master to finish the write
            Wait_Write_Accepted();
            @(posedge HCLK);

            // 5. Verify the data was written correctly despite the delay
            if (Memory[Address>>2] == Data)
                $display("PASS : Wait States Test | Data safely written after delay.");
            else 
                $display("FAIL : Wait States Test");

            Clear_CPU_Interface();
        end
    endtask

    ////////////////////////////////////////////////////////
    // Test: Slave sends an ERROR Response (HRESP = 1)
    ////////////////////////////////////////////////////////
    task automatic Error_Response_Test();
        logic [31:0] Address;
        logic [31:0] Data;
        begin
            Address = 32'h0000_00B0;
            Data    = 32'hDEAD_BEEF;

            $display("\n========== ERROR RESPONSE TEST (HRESP = 1) ==========");

            // 1. Send Command normally
            Send_Command(Address, 3'b000, 3'b010, 1'b1, Data);
            Wait_Command_Accepted();
            CPU_HWDATA <= Data;

            // 2. AHB Error Protocol - Cycle 1: HREADY = 0, HRESP = 1
            @(negedge HCLK);
            HREADY = 1'b0;
            HRESP  = 1'b1;
            $display("-> Slave: ERROR Cycle 1 (HREADY=0, HRESP=1)");
            
            @(posedge HCLK);

            // 3. AHB Error Protocol - Cycle 2: HREADY = 1, HRESP = 1
            @(negedge HCLK);
            HREADY = 1'b1;
            HRESP  = 1'b1;
            $display("-> Slave: ERROR Cycle 2 (HREADY=1, HRESP=1)");
            
            @(posedge HCLK);

            // 4. Check if the Master successfully flagged the error to the CPU
            if (CPU_Error == 1'b1)
                $display("PASS : Master successfully detected the ERROR response!");
            else
                $display("FAIL : Master ignored the ERROR response!");

            // 5. Restore normal Slave state for future tests
            @(negedge HCLK);
            HRESP  = 1'b0;
            
            Clear_CPU_Interface();
        end
    endtask

    ////////////////////////////////////////////////////////
    // Test: Slave sends an ERROR Response during a READ
    ////////////////////////////////////////////////////////
    task automatic Error_Response_Read_Test();
        logic [31:0] Address;
        begin
            Address = 32'h0000_00C0;

            $display("\n========== ERROR RESPONSE READ TEST (HRESP = 1) ==========");

            // 1. Send READ Command
            Send_Command(Address, 3'b000, 3'b010, 1'b0, 32'h0);
            Wait_Command_Accepted();

            // 2. AHB Error Protocol - Cycle 1: HREADY = 0, HRESP = 1
            @(negedge HCLK);
            HREADY = 1'b0;
            HRESP  = 1'b1;
            $display("-> Slave: READ ERROR Cycle 1 (HREADY=0, HRESP=1)");
            
            @(posedge HCLK);

            // 3. AHB Error Protocol - Cycle 2: HREADY = 1, HRESP = 1
            @(negedge HCLK);
            HREADY = 1'b1;
            HRESP  = 1'b1;
            
            // Put garbage data in the memory to simulate a failed read
            // Memory[Address>>2] = 32'hBAD_C0DE; 
            $display("-> Slave: READ ERROR Cycle 2 (HREADY=1, HRESP=1, Garbage Data sent)");
            
            @(posedge HCLK);

            // 4. Verify the Master flagged the error to the CPU
            if (CPU_Error == 1'b1) begin
                $display("PASS : Master successfully detected the READ ERROR!");
                $display("       (The CPU should now ignore the data: %h)", CPU_HRDATA);
            end else begin
                $display("FAIL : Master ignored the READ ERROR response!");
            end

            // 5. Restore normal Slave state for future tests
            @(negedge HCLK);
            HRESP  = 1'b0;
            
            Clear_CPU_Interface();
        end
    endtask

    //initial
    initial begin
        Reset();

        Single_Write();
        Single_Read();

        INCR4_Write();
        INCR4_Read();

        WRAP4_Write();
        WRAP4_Read();

        BackToBack_Write();
        BackToBack_Read();

        Wait_States_Test();
        Error_Response_Test();
        Error_Response_Read_Test();

        #20;
        $stop;
    end

    ////////////////////////////////////////////////////////
    // Dump waveforms for Synopsys Verdi (FSDB format)
    ////////////////////////////////////////////////////////
    initial begin
        // 1. Specify the name of the output waveform file
        $fsdbDumpfile("waves.fsdb"); 
        
        // 2. Dump all variables in the current module (Master_tb) and below (level 0)
        $fsdbDumpvars(0, Master_tb); 
        
        // 3. Dump Multi-Dimensional Arrays (CRITICAL to see the 'Memory' array in Verdi)
        $fsdbDumpMDA(); 
    end
endmodule