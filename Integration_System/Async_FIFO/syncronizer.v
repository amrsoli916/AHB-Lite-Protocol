module syncronizer #(parameter WIDTH=7) (in,clk,out);
    input clk;
    input [WIDTH : 0] in;
    output reg [WIDTH : 0] out;
    reg [WIDTH : 0] q; //output of first flip flop

    always @(posedge clk) begin
        {q,out}<={in,q};
    end

endmodule