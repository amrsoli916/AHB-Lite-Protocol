module dff_with_rstn (
    input clk,
    input rstn,
    input d,
    output reg q
);
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        q <= 0;
    end
    else begin
        q <= d;
    end
end
endmodule