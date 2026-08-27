module reset_synchronizer (
    input logic HCLK,
    input logic ext_resset_n,
    output logic sync_resset
);

logic meta_reg;

always_ff @(posedge HCLK or negedge ext_resset_n) begin 
    if (!ext_resset_n) begin
        meta_reg <= 0;
        sync_resset <= 0;
    end
    else begin
        meta_reg <= 1'b1;
        sync_resset <= meta_reg;
    end
end
    
endmodule