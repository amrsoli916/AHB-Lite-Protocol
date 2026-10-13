module level_to_pulse (
    input   clk,
    input   rst_n,
    input   level,
    output reg  pulse
);

    reg level_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            level_d <= 1'b0;
            pulse   <= 1'b0;
        end
        else begin
            level_d <= level;
            pulse   <= level & ~level_d;
        end
    end

endmodule