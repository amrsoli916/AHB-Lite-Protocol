// Module      : instruction_memory
// Description : Byte-addressable instruction memory
//               with asynchronous 32-bit instruction read

module instruction_memory #(
    parameter integer DEPTH = 1024,
    parameter         INIT_FILE = "program.txt")(
    input  wire [31:0] addr,
    output wire [31:0] rd_data
);

    localparam integer ADDR_WIDTH = $clog2(DEPTH);
    localparam [31:0] LAST_VALID_ADDR = DEPTH - 4;

    reg [7:0] mem [0:DEPTH-1];

    integer i;

    wire [ADDR_WIDTH-1:0] byte_addr;
    wire                  valid_fetch;

    initial begin

        // Fill unused memory locations with zero instructions
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 8'h00;

        $display("Loading program from %0s", INIT_FILE);
        $readmemh(INIT_FILE, mem);

    end

    assign byte_addr = addr[ADDR_WIDTH-1:0];

    // Instructions must be word-aligned and inside the memory range
    assign valid_fetch =
        (addr[1:0] == 2'b00) &&
        (addr <= LAST_VALID_ADDR);

    // Little-endian instruction assembly
    assign rd_data = valid_fetch ? {
            		mem[byte_addr + 3],
            		mem[byte_addr + 2],
            		mem[byte_addr + 1],
            		mem[byte_addr]}: 32'h00000000;

endmodule
