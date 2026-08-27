module mux2 #(parameter WIDTH = 32)
(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             sel,

    output wire [WIDTH-1:0] y
);

assign y = sel ? b : a;

endmodule
