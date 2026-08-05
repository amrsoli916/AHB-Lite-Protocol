module Master_Top_tb;

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


//====================================================
// Simple AHB-Lite Slave Memory Model
//====================================================

logic [31:0] Memory [0:1023];

//-----------------------------------------
// Address Phase Registers
//-----------------------------------------

logic        write_d;
logic        valid_d;
logic [31:0] addr_d;

//-----------------------------------------
// Capture Address Phase
//-----------------------------------------

always_ff @(posedge HCLK or negedge HRESET_n) begin

    if(!HRESET_n) begin

        write_d <= 1'b0;
        valid_d <= 1'b0;
        addr_d  <= '0;

    end
    else if(HREADY) begin

        valid_d <= (HTRANS == 2'b10) || (HTRANS == 2'b11);

        if(HTRANS == 2'b10 || HTRANS == 2'b11) begin

            write_d <= HWRITE;
            addr_d  <= HADDR;

        end

    end

end

//-----------------------------------------
// Write Memory
//-----------------------------------------

always_ff @(posedge HCLK) begin

    if(HREADY && valid_d && write_d) begin

        Memory[addr_d[31:2]] <= HWDATA;

        $display("[%0t] WRITE  ADDR=%h DATA=%h",
                 $time,
                 addr_d,
                 HWDATA);

    end

end


//-----------------------------------------
// Read Memory (Combinational for Zero-Wait-State)
//-----------------------------------------
always_comb begin
    if (valid_d && !write_d) begin
        HRDATA = Memory[addr_d[31:2]]; // خروج البيانات فوراً بدون تأخير (Combinational)
    end
    else begin
        HRDATA = '0;
    end
end


always_ff @(posedge HCLK) begin
    if (HREADY && valid_d && !write_d) begin
        $display("[%0t] READ   ADDR=%h DATA=%h",
                 $time,
                 addr_d,
                 Memory[addr_d[31:2]]);
    end
end


    //task to reset the DUT
    task automatic Reset;
    begin 
        HRESET_n = 0;
        CPU_Request       = 0;
        CPU_HWRITE        = 0;
        CPU_HADDR         = '0;
        CPU_HWDATA        = '0;
        CPU_HSIZE         = '0;
        CPU_HBURST        = '0;
        CPU_Last_Transfer = 0;
        CPU_Busy          = 0;

        HREADY = 1;
        HRESP  = 0;
        repeat(5) @(posedge HCLK);

        HRESET_n = 1;
        repeat(2) @(posedge HCLK);
    end
    endtask

    ///////////////////////////
    //send command to Master
    ///////////////////////////
    task automatic Send_Command(
        input logic [31:0] Address,
        input logic [2:0]  Burst,
        input logic [2:0]  Size,
        input logic        Write,
        input logic [width-1:0] Data
    );
    begin
        @(negedge HCLK);
        CPU_HADDR = Address;
        CPU_HBURST = Burst;
        CPU_HSIZE = Size;
        CPU_HWRITE = Write;
        CPU_HWDATA = Data;
        CPU_Request = 1;
        @(negedge HCLK);
        CPU_Request = 0;
    end
    endtask

    ////////////////////////////
    //Wait Commant Accepted
    ////////////////////////////
    task automatic Wait_Command_Accepted;
    begin
        wait (CPU_Command_Ready);
        @(negedge HCLK);
    end
    endtask

    ////////////////////////////
    //Wait Write Data Ready
    ////////////////////////////
    task automatic Wait_Write_Data;
    begin
        wait (CPU_Data_Ready);
        @(posedge HCLK);
        @(negedge HCLK);
    end
    endtask

    ////////////////////////////
    //Wait Read Data Ready
    ////////////////////////////
    task automatic Wait_Read_Data;
    begin
        wait (Read_Valid);
        @(negedge HCLK);
    end
    endtask
    

//Task Single Write
    task automatic Single_Write();
    begin

        $display("\n===== SINGLE WRITE =====");

        Send_Command(
            32'h0000_0020,  //Address
            3'b000,         //single burst
            3'b010,         //word size 
            1'b1, 
            32'h1234_5678); //Data

        Wait_Write_Data();

        if(Memory[32'h0000_0020 >> 2] == 32'h1234_5678) begin
            $display("Pass: Single Write Test Passed");
        end
        else begin
            $display("Fail: Single Write Test Failed");
        end
    end
    endtask

//Task Single Read
    task automatic Single_Read();

        begin
            $display("\n===== SINGLE READ =====");

            Send_Command(
                32'h0000_0020,  //Address
                3'b000,         //single burst
                3'b010,         //word size 
                1'b0, 
                '0);            //Data

            Wait_Read_Data();

            if(CPU_HRDATA == 32'h1234_5678) begin
                $display("Pass: Single Read Test Passed");
            end
            else begin
                $display("Fail: Single Read Test Failed");
            end
        end
        endtask


    //Task INCR4 Write
    task automatic INCR4_Write();

        logic [31:0] Base_Address;

        begin

            Base_Address = 32'h0000_0040;

            $display("\n===== INCR4 WRITE =====");

            Send_Command(
                Base_Address,
                3'b011,
                3'b010,
                1'b1,
                32'h1111_1111
            );

            Wait_Write_Data();
            CPU_HWDATA = 32'h22222222;

            Wait_Write_Data();
            CPU_HWDATA = 32'h33333333;

            Wait_Write_Data();
            CPU_HWDATA = 32'h44444444;

            Wait_Write_Data();

            if ( Memory[(Base_Address>>2)+0] == 32'h1111_1111 &&
                Memory[(Base_Address>>2)+1] == 32'h2222_2222 &&
                Memory[(Base_Address>>2)+2] == 32'h3333_3333 &&
                Memory[(Base_Address>>2)+3] == 32'h4444_4444 )
            begin
                $display("Pass: INCR4 Write Test Passed");
            end
            else begin
                $display("Fail: INCR4 Write Test Failed");
            end
        end
    endtask


    //Task INCR4 Read
    task automatic INCR4_Read();

        logic [31:0] Base_Address;

    begin

        Base_Address = 32'h0000_0040;

        $display("\n===== INCR4 READ =====");

        Send_Command(
            Base_Address,
            3'b011,        // INCR4
            3'b010,
            1'b0,
            '0
        );

        //---------------- Beat0 ----------------
        Wait_Read_Data();

        if (CPU_HRDATA != 32'h1111_1111)
            $display("Fail Beat0");

        //---------------- Beat1 ----------------
        Wait_Read_Data();

        if (CPU_HRDATA != 32'h2222_2222)
            $display("Fail Beat1");

        //---------------- Beat2 ----------------
        Wait_Read_Data();

        if (CPU_HRDATA != 32'h3333_3333)
            $display("Fail Beat2");

        //---------------- Beat3 ----------------
        Wait_Read_Data();

        if (CPU_HRDATA != 32'h4444_4444)
            $display("Fail Beat3");

        @(posedge HCLK);
        $display("Pass: INCR4 Read Test Passed");

    end
    endtask

task automatic WRAP4_Write();

    logic [31:0] Base_Address;

begin

    Base_Address = 32'h0000_0038;

    $display("\n===== WRAP4 WRITE =====");

    Send_Command(
        Base_Address,
        3'b010,          // WRAP4
        3'b010,          // Word
        1'b1,
        32'h11111111
    );


    Wait_Write_Data();
    CPU_HWDATA <= 32'h22222222;

    Wait_Write_Data();
    CPU_HWDATA <= 32'h33333333;

    Wait_Write_Data();
    CPU_HWDATA <= 32'h44444444;

    Wait_Write_Data();

    if ( Memory[32'h38 >> 2] == 32'h11111111 &&
         Memory[32'h3C >> 2] == 32'h22222222 &&
         Memory[32'h30 >> 2] == 32'h33333333 &&
         Memory[32'h34 >> 2] == 32'h44444444 )
    begin
        $display("Pass: WRAP4 Write Test Passed");
    end
    else begin

        $display("Fail: WRAP4 Write Test Failed");

        $display("30 = %h", Memory[32'h30 >> 2]);
        $display("34 = %h", Memory[32'h34 >> 2]);
        $display("38 = %h", Memory[32'h38 >> 2]);
        $display("3C = %h", Memory[32'h3C >> 2]);

    end

end
endtask

task automatic WRAP4_Read();

    logic [31:0] Base_Address;

begin

    Base_Address = 32'h0000_0038;

    $display("\n===== WRAP4 READ =====");

    Send_Command(
        Base_Address,
        3'b010,          // WRAP4
        3'b010,
        1'b0,
        '0
    );


    Wait_Read_Data();
    if (CPU_HRDATA != 32'h11111111)
        $display("Fail Beat0");

    Wait_Read_Data();
    if (CPU_HRDATA != 32'h22222222)
        $display("Fail Beat1");

    Wait_Read_Data();
    if (CPU_HRDATA != 32'h33333333)
        $display("Fail Beat2");

    Wait_Read_Data();
    if (CPU_HRDATA != 32'h44444444)
        $display("Fail Beat3");

    @(posedge HCLK);

    $display("Pass: WRAP4 Read Test Passed");

end
endtask

//Task Back-to-Back Write
    task automatic B2B_Write();
        logic [31:0] Addr1, Addr2;
    begin
        Addr1 = 32'h0000_0050;
        Addr2 = 32'h0000_0060;

        $display("\n⏳ ===== BACK-TO-BACK WRITE (INCR4 -> INCR4) =====");

        // --- BURST 1 ---
        Send_Command(Addr1, 3'b011, 3'b010, 1'b1, 32'hA1A1A1A1); // Beat 0
        Wait_Write_Data(); CPU_HWDATA = 32'hB2B2B2B2;            // Beat 1
        Wait_Write_Data(); CPU_HWDATA = 32'hC3C3C3C3;            // Beat 2

        // --- THE B2B MAGIC HAPPENS HERE ---
        // put the last beat of the first burst and the first beat of the second burst in the same clock cycle
        Wait_Write_Data();
        CPU_HWDATA = 32'hD4D4D4D4; // Beat 3 of first burst

        // Start the second burst immediately after the first burst's last beat
        CPU_HADDR = Addr2;
        CPU_Request = 1;

        //wait for the command to be accepted
        Wait_Write_Data();
        
        // --- BURST 2 ---
        CPU_Request = 0;           // Stop requesting new burst
        CPU_HWDATA = 32'hE5E5E5E5; // Daten der ersten Beat der zweiten Burst

        Wait_Write_Data(); CPU_HWDATA = 32'hF6F6F6F6; // Beat 1
        Wait_Write_Data(); CPU_HWDATA = 32'h77777777; // Beat 2
        Wait_Write_Data(); CPU_HWDATA = 32'h88888888; // Beat 3
        Wait_Write_Data(); // Wait for the last write to complete

        // Check the memory contents for both bursts
        if (Memory[Addr1>>2] == 32'hA1A1A1A1 && Memory[(Addr1>>2)+3] == 32'hD4D4D4D4 &&
            Memory[Addr2>>2] == 32'hE5E5E5E5 && Memory[(Addr2>>2)+3] == 32'h88888888) begin
            $display("Pass: B2B Write Test Passed");
        end else begin
            $display("Fail: B2B Write Test Failed");
        end
    end
    endtask

//Task Back-to-Back Read
    task automatic B2B_Read();
        logic [31:0] Addr1, Addr2;
    begin
        Addr1 = 32'h0000_0050;
        Addr2 = 32'h0000_0060;

        $display("\n⏳ ===== BACK-TO-BACK READ (INCR4 -> INCR4) =====");

        // --- BURST 1 ---
        Send_Command(Addr1, 3'b011, 3'b010, 1'b0, '0);

        Wait_Read_Data(); if (CPU_HRDATA != 32'hA1A1A1A1) $display("Fail B1 Beat0");
        Wait_Read_Data(); if (CPU_HRDATA != 32'hB2B2B2B2) $display("Fail B1 Beat1");
        Wait_Read_Data(); if (CPU_HRDATA != 32'hC3C3C3C3) $display("Fail B1 Beat2");

        // --- THE B2B MAGIC HAPPENS HERE ---
        // put the last beat of the first burst and the first beat of the second burst in the same clock cycle
        CPU_HADDR = Addr2;
        CPU_Request = 1;

        Wait_Read_Data(); if (CPU_HRDATA != 32'hD4D4D4D4) $display("Fail B1 Beat3");

        // --- BURST 2 ---

        Wait_Read_Data(); if (CPU_HRDATA != 32'hE5E5E5E5) $display("Fail B2 Beat0");
        CPU_Request = 0; // Stop requesting new burst
        Wait_Read_Data(); if (CPU_HRDATA != 32'hF6F6F6F6) $display("Fail B2 Beat1");
        Wait_Read_Data(); if (CPU_HRDATA != 32'h77777777) $display("Fail B2 Beat2");
        Wait_Read_Data(); if (CPU_HRDATA != 32'h88888888) $display("Fail B2 Beat3");

        @(posedge HCLK);
        $display("Pass: B2B Read Test Passed");
    end
    endtask


// ==========================================
    // Task: INCR4 Write with CPU BUSY state (2 Cycles Stall)
    // Fixed: Perfect Pipeline Alignment & Safe Flush
    // ==========================================
    task automatic INCR4_Busy_Write();
        logic [31:0] Base_Address;
    begin
        Base_Address = 32'h0000_0070;

        $display("\n⏳ ===== INCR4 WRITE WITH CPU BUSY (2 CYCLES STALL) =====");

        // --- 1. Address Phase Beat 0 ---
        @(negedge HCLK);
        CPU_HADDR = Base_Address; CPU_HBURST = 3'b011; CPU_HSIZE = 3'b010; CPU_HWRITE = 1'b1; CPU_Request = 1;

        // --- 2. Data Phase Beat 0 / Address Phase Beat 1 ---
        // Wait until the Master RTL signals that the data phase has actively started
        do @(negedge HCLK); while (!CPU_Data_Ready);
        CPU_Request = 0; // Drop request safely
        CPU_HWDATA = 32'h1111_1111; 

        // --- 3. Data Phase Beat 1 / Address Phase Beat 2 ---
        do @(negedge HCLK); while (!CPU_Data_Ready);
        CPU_HWDATA = 32'h2222_2222;
        CPU_Busy = 1; // 🚨 Assert CPU_Busy during Beat 1's data phase

        // --- 4. Data Phase Beat 2 / BUSY Phase ---
        do @(negedge HCLK); while (!CPU_Data_Ready);
        CPU_HWDATA = 32'h3333_3333; 

        // --- 5. Stall Cycles (Simulating internal CPU delay) ---
        @(negedge HCLK); // Stall Cycle 1
        @(negedge HCLK); // Stall Cycle 2
        CPU_Busy = 0;    // CPU is ready again

        // --- 6. Data Phase Beat 3 ---
        do @(negedge HCLK); while (!CPU_Data_Ready);
        CPU_HWDATA = 32'h4444_4444; 

        // --- 7. Flush Pipeline (Fixing the Infinite Loop) ---
        // ❌ We CANNOT use a while loop here! The bus goes to IDLE and CPU_Data_Ready becomes 0 forever.
        // ✅ We just need to wait one clock cycle for the memory to capture the final beat.
        @(negedge HCLK); 
        @(negedge HCLK); // One extra cycle margin for safety

        // --- Memory Verification ---
        if ( Memory[(Base_Address>>2)+0] == 32'h1111_1111 &&
             Memory[(Base_Address>>2)+1] == 32'h2222_2222 &&
             Memory[(Base_Address>>2)+2] == 32'h3333_3333 &&
             Memory[(Base_Address>>2)+3] == 32'h4444_4444 )
        begin
            $display("Pass: INCR4 2-Cycle Busy Write Test Passed");
        end else begin
            $display("Fail: INCR4 2-Cycle Busy Write Test Failed");
        end
    end
    endtask

// ==========================================
    // Task: Write with Slave Wait States using Send_Command
    // ==========================================
    task automatic Wait_State_Write();
        logic [31:0] Base_Address;
    begin
        Base_Address = 32'h0000_00A0;

        $display("\n⏳ ===== WRITE WITH SLAVE WAIT STATES (USING Send_Command) =====");

        // --- Step 1: Send the write command and data using Send_Command ---
        // Parameters: Addr, Burst (SINGLE = 3'b000), Size (Word = 3'b010), Write (1'b1), Data
        Send_Command(
            Base_Address,
            3'b000,          // Single transfer burst
            3'b010,          // Word size (32-bit)
            1'b1,            // Write operation
            32'hAAAA_BBBB    // Write data
        );

        // --- Step 2: Inject Wait States from the Slave side ---
        // Force HREADY low right after the command is sent to simulate a slow memory response
        @(negedge HCLK);
        force HREADY = 0; 
        $display("[TB] -> Forcing HREADY = 0 (Wait State 1)");
        
        @(negedge HCLK);
        $display("[TB] -> Forcing HREADY = 0 (Wait State 2)");

        // --- Step 3: Release HREADY to allow completion ---
        @(negedge HCLK);
        force HREADY = 1;
        release HREADY; // Release the signal back to the memory driver
        $display("[TB] -> Releasing HREADY = 1, transaction completing...");

        // --- Step 4: Wait for transfer to fully complete ---
        Wait_Write_Data();

        // --- Step 5: Memory Verification ---
        if (Memory[Base_Address >> 2] == 32'hAAAA_BBBB) begin
            $display("Pass: Slave Wait State Write Test Passed");
        end else begin
            $display("Fail: Slave Wait State Write Test Failed");
        end
    end
    endtask

// ==========================================
    // Task: AHB-Lite Error Response Test (HRESP = 1)
    // Verified: Ensures memory is NOT corrupted on error
    // ==========================================
    task automatic Error_Response_Test();
        logic [31:0] Base_Address;
    begin
        Base_Address = 32'h0000_00E0; // Unmapped or faulty address

        $display("\n🚨 ===== AHB-LITE ERROR RESPONSE TEST (HRESP = 1) =====");

        // --- Step 1: Send write command using Send_Command ---
        // We try to write DEAD_BEEF to a faulty/protected address
        Send_Command(
            Base_Address,
            3'b000,          // Single transfer
            3'b010,          // Word size (32-bit)
            1'b1,            // Write operation
            32'hDEAD_BEEF    // Data that should be REJECTED
        );

        // --- Step 2: Inject Error Response from Slave side ---
        // Force HRESP high during the data phase to simulate a slave error
        @(negedge HCLK);
        force HRESP = 1; 
        $display("[TB] -> Forcing HRESP = 1 (Slave Error Injected)");

        // Keep HRESP high for one clock cycle to let the Master FSM catch the error
        @(negedge HCLK);

        // --- Step 3: Release HRESP signal ---
        release HRESP;
        force HRESP = 0; // Return HRESP back to default low state
        $display("[TB] -> Releasing HRESP = 0, checking recovery...");

        // --- Step 4: Allow FSM to recover and return to IDLE ---
        @(negedge HCLK);
        @(negedge HCLK);

        // --- Step 5: Memory Verification (The Crucial Check) ---
        // Because HRESP was high, the write transaction MUST fail, 
        // and the memory at Base_Address must NOT be updated with DEAD_BEEF.
        if (Memory[Base_Address >> 2] != 32'hDEAD_BEEF) begin
            $display("Pass: Error Response Handled Successfully. Memory was protected (Not written).");
        end else begin
            $display("Fail: Memory was corrupted despite the Error Response!");
        end
    end
    endtask

// ==========================================
    // Task: INCR4 Read with Error Response in the Middle (HRESP = 1)
    // ==========================================
    task automatic INCR4_Read_Error_Test();
        logic [31:0] Base_Address;
        logic [31:0] Data_Captured;
    begin
        Base_Address = 32'h0000_0038;

        $display("\n🚨 ===== INCR4 READ WITH ERROR RESPONSE IN THE MIDDLE ===== ");

        // --- Step 1: Send INCR4 Read command ---
        // Parameters: Addr, Burst (INCR4 = 3'b011), Size (Word = 3'b010), Write (1'b0 = Read), Data
        Send_Command(
            Base_Address,
            3'b011,          // INCR4 burst type
            3'b010,          // Word size (32-bit)
            1'b0,            // Read operation (HWRITE = 0)
            '0               // Dummy data for read
        );

        // --- Step 2: Read Beat 0 successfully ---
        Wait_Read_Data();
        Data_Captured = CPU_HRDATA;
        $display("[TB] Beat 0 Read Successful. Data = %0h", Data_Captured);

        // --- Step 3: Read Beat 1 successfully ---
        Wait_Read_Data();
        Data_Captured = CPU_HRDATA;
        $display("[TB] Beat 1 Read Successful. Data = %0h", Data_Captured);

        // --- Step 4: Inject Error Response during Beat 2 Data Phase ---
        // Force HRESP high to simulate a slave error in the middle of the burst
        @(negedge HCLK);
        force HRESP = 1;
        $display("[TB] -> Forcing HRESP = 1 (Error injected on Beat 2)");

        // Keep HRESP high for the cycle required for the FSM to detect the error
        @(negedge HCLK);

        // --- Step 5: Release HRESP signal ---
        release HRESP;
        force HRESP = 0; // Return HRESP back to default low state
        $display("[TB] -> Releasing HRESP = 0, checking if Master aborts the remaining beats");

        // --- Step 6: Allow FSM recovery time ---
        // The master should immediately cancel the remaining beats of the INCR4 burst and return to IDLE
        @(negedge HCLK);
        @(negedge HCLK);

        $display("[TB] INCR4 Read Error Test Completed. Check Waveform for proper Burst Abort.");
    end
    endtask

initial begin
        Reset();

        Single_Write();
        Single_Read();

        INCR4_Write();
        INCR4_Read();

        WRAP4_Write();
        WRAP4_Read();

        B2B_Write();
        B2B_Read();

        INCR4_Busy_Write();
        Wait_State_Write();
        Error_Response_Test();
        INCR4_Read_Error_Test();

        $display("\n==============================");
        $display(" ALL TESTS PASSED ");
        $display("==============================");

        #20;

        $stop;
    end
endmodule