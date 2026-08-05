module Address_Generator (
    input logic [31:0] Start_Address,
    input logic [31:0] Current_Address,

    input logic [2:0] HSIZE,
    input logic [2:0] HBURST,

    output logic [31:0] Next_Address
);

logic [31:0] increment;
logic [4:0] burst_length;
logic [31:0] boundary_size;
logic [31:0] wrap_boundary;
logic [31:0] next_linear_address;


//Decode HBURST type 
typedef enum logic [2:0]
{
    SINGLE = 3'b000,
    INCR   = 3'b001,
    WRAP4  = 3'b010,
    INCR4  = 3'b011,
    WRAP8  = 3'b100,
    INCR8  = 3'b101,
    WRAP16 = 3'b110,
    INCR16 = 3'b111

} hburst_t;

assign increment = 32'd1 << HSIZE;

//calculate the burst_lenght for burst
always_comb begin

    case(HBURST)

        WRAP4,
        INCR4:
            burst_length = 5'd4;

        WRAP8,
        INCR8:
            burst_length = 5'd8;

        WRAP16,
        INCR16:
            burst_length = 5'd16;

        default:
            burst_length = 5'd1;

    endcase
end

always_comb begin

    Next_Address = Current_Address;

    case(HBURST)

        SINGLE,
        INCR,
        INCR4,
        INCR8,
        INCR16:
        begin
            Next_Address = next_linear_address;
        end

        WRAP4,
        WRAP8,
        WRAP16:
        begin
            if(next_linear_address >= (wrap_boundary + boundary_size))
                Next_Address = wrap_boundary;

            else
                Next_Address = next_linear_address;
        end

        default:
            Next_Address = Current_Address;

    endcase

end

assign boundary_size = burst_length * increment;
assign wrap_boundary = Start_Address & ~(boundary_size - 1);
assign next_linear_address = Current_Address + increment;
    
endmodule