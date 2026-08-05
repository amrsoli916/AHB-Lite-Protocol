module FSM (
    input logic HCLK,
    input logic HRESET_n,

    //AHB
    input logic Request,
    input logic Busy,

    //Burst Control
    input logic TransferDone,
    input logic Last_Beat,

    //From Slave
    input logic HREADY,
    input logic HRESP,

    //TimeOut
    input logic TimeOut,

    //Output

    //To Burst Counter
    output logic Decrement_counter,
    output logic Load_Counter,

    //To Addrees Register
    output logic Load_Start_Address,
    output logic Increment_Address,

    //To write enable & register enable 
    output logic Capture_Control_Signal,
    output logic Data_Phase_Active,

    //output from master and control for slave 
    output logic [1:0] HTRANS
);

localparam logic [1:0] HTRANS_IDLE   = 2'b00;
localparam logic [1:0] HTRANS_BUSY   = 2'b01;
localparam logic [1:0] HTRANS_NONSEQ = 2'b10;
localparam logic [1:0] HTRANS_SEQ    = 2'b11;


typedef enum logic [1:0] 
{ 
    IDLE,
    LOAD,
    TRANSFER,
    BUSY
} state_t;

state_t current_state, next_state;

//next state 
always_ff @(posedge HCLK or negedge HRESET_n) begin 
    if (!HRESET_n) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

//select next state depend on currnt state 
always_comb begin 
    // Default assignment to prevent latches
    next_state = current_state;

    case (current_state)
        // If we are in IDLE state 
        IDLE : begin
            if (Request) begin
                next_state = LOAD;          // Request came
            end
            else begin
                next_state = IDLE;          // No Request
            end
        end

        // If we are in LOAD state 
        LOAD : begin
            if (TimeOut || HRESP) begin
                next_state = IDLE;
            end
            else if (HREADY) begin
                next_state = TRANSFER;      // Slave accepted the first address
            end
            else begin
                next_state = LOAD;
            end
        end

        // If we are in TRANSFER state 
        TRANSFER : begin
            if (TimeOut || HRESP) begin
                next_state = IDLE;          // Error priority
            end
            else if (TransferDone) begin    // TransferDone implies (Last_Beat && HREADY)
                // We are at the END of the burst
                if (Request) begin
                    next_state = TRANSFER;  // Back-to-back Burst
                end
                else begin
                    next_state = IDLE;      // Burst finished, bus is free
                end
            end
            // We are in the MIDDLE of a burst, check if CPU needs to pause
            else if (HREADY && Busy) begin 
                next_state = BUSY;          // Inject Wait States from Master side
            end
            else begin
                next_state = TRANSFER;      // Continue normally OR wait for slave (HREADY=0)
            end
        end

        // If we are in BUSY state
        BUSY : begin
            if (TimeOut || HRESP) begin
                next_state = IDLE;          // Error priority
            end
            else if (HREADY && !Busy) begin
                next_state = TRANSFER;      // Slave accepted the transfer, go back to TRANSFER state
            end
            else begin
                next_state = BUSY;          // Continue to wait for slave (HREADY=0)
            end
        end
        
        default: next_state = IDLE;
    endcase
end

//output every signal in each state 
always_comb begin 
    
    Decrement_counter  = 1'b0;
    Load_Counter       = 1'b0;
    Load_Start_Address = 1'b0; 
    Increment_Address  = 1'b0;
    HTRANS             = HTRANS_IDLE;

    case (current_state) 

        ///////////////////////////////
        //IDLE_STATE
        //////////////////////////////
       IDLE : begin
        HTRANS = HTRANS_IDLE;
       end

        ///////////////////////////////
        //LOAD_STATE
        ////////////////////////////// 
        LOAD : begin
            Load_Counter       = 1'b1;
            Load_Start_Address = 1'b1;

            HTRANS = HTRANS_NONSEQ;
        end 

        ///////////////////////////////
        //TRANSFER_STATE
        //////////////////////////////  
        TRANSFER : begin

            if(Last_Beat)begin
                if(Request)begin
                    HTRANS = HTRANS_NONSEQ;  // Back-to-back Burst
                end
                else begin
                    HTRANS = HTRANS_IDLE;     // Burst finished, bus is free
                end
            end
            else begin
                HTRANS = HTRANS_SEQ;          // Continue normally OR wait for slave (HREADY=0)
            end
            
            if(HREADY)begin
                Decrement_counter = 1'b1;
                if(Last_Beat)begin
                    if(Request)begin
                        Load_Counter       = 1'b1;          // Back-to-back Burst
                        Load_Start_Address = 1'b1;          // Load new start address
                    end
                end
                else begin
                    Increment_Address = 1'b1;
                end
            end
        end 

        ///////////////////////////////
        //BUSY_STATE
        //////////////////////////////
        BUSY : begin
            HTRANS = HTRANS_BUSY;
        end

        default: HTRANS = HTRANS_IDLE;           
    endcase
end

//signal to enable the registeer to capture the state of HWRITE during the data phase. 
//This is used to determine if the current transfer is a read or write operation.
assign Capture_Control_Signal = HREADY && Load_Start_Address;

always_ff @(posedge HCLK or negedge HRESET_n) begin
    if (!HRESET_n)
        Data_Phase_Active <= 1'b0;
    else if (HREADY) begin
        if (HTRANS == 2'b10 || HTRANS == 2'b11)                      // NONSEQ or SEQ
            Data_Phase_Active <= 1'b1;                              //  Data Phase
        else if (HTRANS == 2'b00 || HTRANS == 2'b01)               // IDLE & Busy
            Data_Phase_Active <= 1'b0;        
    end
end

    
endmodule