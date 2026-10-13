module two_one_mux#(
    parameter INPUT_WIDTH = 32
)(
    input   sel,
    input  [INPUT_WIDTH-1:0] in0,
    input  [INPUT_WIDTH-1:0] in1,
    output [INPUT_WIDTH-1:0] out
);

assign out = sel?in1:in0;
endmodule