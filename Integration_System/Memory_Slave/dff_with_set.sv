module dff_with_set (
    input clk,
    input set,
    input d,
    output reg q
);
always @(posedge clk or posedge set) begin
    if(set) begin
        q <= 1;
    end
    else begin
        q <= d;
    end
end
endmodule