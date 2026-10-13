module rstn_sync (
    input clk,
    input rstn,
    input d,
    output q
);

wire int_wire;

dff_with_rstn f1 (
    .clk(clk),
    .rstn(rstn),
    .d(1),
    .q(int_wire)
);

dff_with_rstn f2 (
    .clk(clk),
    .rstn(rstn),
    .d(int_wire),
    .q(q)
);
endmodule