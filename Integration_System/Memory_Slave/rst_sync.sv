module rst_sync (
    input clk,
    input rst,
    output q
);

wire int_wire;

dff_with_set ff1 (
    .clk(clk),
    .set(rst),
    .d(1'b0),
    .q(int_wire)
);

dff_with_set ff2 (
    .clk(clk),
    .set(rst),
    .d(int_wire),
    .q(q)
);
endmodule