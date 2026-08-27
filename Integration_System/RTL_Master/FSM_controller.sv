module FSM (
    input logic HCLK,
    input logic HRESET_n,

    //AHB
    input logic Request,
    input logic Busy,

    //Burst Control
    input logic TransferDone,
    input logic First_Beat,

    //From Slave
    input logic HREADY,
    input logic HRESP,

    //TimeOut
    input logic TimeOut,


    //To Burst Counter
    output logic Decrement_counter,
    output logic Load_Counter,

    //To Addrees Register
    output logic Load_Start_Address,
    output logic Increment_Address,

    //To write enable & register enable 
    output logic Address_Accepted,

    //output from master and control for slave 
    output logic [1:0] HTRANS,
    output logic CPU_Command_Ready
);

localparam logic [1:0] HTRANS_IDLE   = 2'b00;
localparam logic [1:0] HTRANS_BUSY   = 2'b01;
localparam logic [1:0] HTRANS_NONSEQ = 2'b10;
localparam logic [1:0] HTRANS_SEQ    = 2'b11;


typedef enum logic [1:0] 
{ 
    IDLE,
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
                next_state = TRANSFER;          // Request came
            end
            else begin
                next_state = IDLE;          // No Request
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

            if (Request && HREADY) begin
                Load_Counter       = 1'b1;
                Load_Start_Address = 1'b1;
            end

        end

        ///////////////////////////////
        //TRANSFER_STATE
        //////////////////////////////  
        TRANSFER : begin

            // HTRANS
            if (First_Beat)
                HTRANS = HTRANS_NONSEQ;
                
            else
                HTRANS = HTRANS_SEQ;


            if (HREADY) begin

                Decrement_counter = 1'b1;

                if (TransferDone) begin

                    if (Request) begin
                        Load_Counter       = 1'b1;
                        Load_Start_Address = 1'b1;
                    end

                end
                else begin
                    Increment_Address = 1'b1;
                end
            end
        end

        default: HTRANS = HTRANS_IDLE;           
    endcase
end

//signal to enable the registeer to capture the state of HWRITE during the data phase. 
//This is used to determine if the current transfer is a read or write operation.
assign Address_Accepted = HREADY && (HTRANS == HTRANS_NONSEQ || HTRANS == HTRANS_SEQ);

always_ff @(posedge HCLK or negedge HRESET_n) begin : blockName
    if (!HRESET_n) begin
        CPU_Command_Ready <= 1'b0;
    end
    else begin
        CPU_Command_Ready <= 1'b0;
        
        if ((TransferDone && HREADY) || (current_state == IDLE)) begin
            CPU_Command_Ready <= 1'b1;
        end
    end
end 

endmodule