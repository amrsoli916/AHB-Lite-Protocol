module FSM (
    input logic HCLK,
    input logic HRESET_n,

    //AHB
    input logic Request,
    input logic HWRITE,

    //Burst Control
    input logic TransferDone,

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

    //To write read enable 
    output logic Write_enable,
    output logic Read_enable,

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
    TRANSFER
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

    next_state = current_state;

    case (current_state)
        //if we in IDLE state 
       IDLE : begin
        if (Request) begin
            next_state = LOAD;          //Request come
        end
        else begin
            next_state = IDLE;          //Not Request come
        end
       end

        //If we in LOAD state 
        LOAD : begin
            next_state = TRANSFER;      //next state is Transfer 
        end

        //If we in Transfer state 
        TRANSFER : begin
            if (TimeOut || HRESP) begin
                next_state = IDLE;
            end
            else if (TransferDone && HREADY) begin
                if (Request) begin
                    next_state = LOAD;
                end
                else begin
                    next_state = IDLE;
                end
            end
            else begin
                next_state = TRANSFER;
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
    Write_enable       = 1'b0;
    Read_enable        = 1'b0;
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

            if (HWRITE) begin
                Write_enable = 1'b1;
            end
            else begin
                Read_enable = 1'b1;
            end
        end 

        ///////////////////////////////
        //TRANSFER_STATE
        //////////////////////////////  
        TRANSFER : begin

            HTRANS = HTRANS_SEQ;

            if (HREADY && !TransferDone) begin
                Decrement_counter = 1'b1;
                Increment_Address = 1'b1;
            end


            ////////////////////////////////////////////////////////////////////////////////////////////////////
            //HERE can Handle BUSY state if we add a fifo when it empty or full control this if it read or write 
            ////////////////////////////////////////////////////////////////////////////////////////////////////
            //if donot handle can master transimite data wider than it's width put signal size_error
            //when it high go to idle state 
            ////////////////////////////////////////////////////////////////////////////////////////////////////
        end 

        default: HTRANS = HTRANS_IDLE;           
    endcase
end

    
endmodule