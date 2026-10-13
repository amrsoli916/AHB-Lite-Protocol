module double_flop_sync(
    input clk,
    input in,
    output reg out
);

reg int_wire;
always @(posedge clk) begin
    int_wire <= in;
    out      <= int_wire;
end

endmodule