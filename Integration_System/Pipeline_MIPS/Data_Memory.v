module Data_Memory (
    input  wire        clk,
    input  wire        WE,
    input  wire [31:0] Address,
    input  wire [31:0] WriteData,
    output wire [31:0] ReadData
);

    reg [31:0] RAM [0:127];
    integer i;
    wire [6:0] word_addr;
    wire       aligned;

    assign word_addr = Address[8:2];
    assign aligned   = (Address[1:0] == 2'b00);

    assign ReadData =
        aligned ? RAM[word_addr] : 32'b0;

    always @(posedge clk) begin
        if (WE && aligned)
            RAM[word_addr] <= WriteData;
    end

    initial begin
        for (i = 0; i < 128; i = i + 1)
            RAM[i] = 32'b0;
    end

endmodule
