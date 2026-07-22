`timescale 1ns / 1ps
// ============================================================================
// 7. COMBINATIONAL BINARY TO BCD (Double Dabble)
// ============================================================================
module binary_to_bcd (
    input [13:0] binary_in,
    output reg [15:0] bcd_out
);
    integer i;
    
    always @(*) begin
        bcd_out = 16'd0; 
        
        for (i = 13; i >= 0; i = i - 1) begin
            if (bcd_out[3:0]   >= 5) bcd_out[3:0]   = bcd_out[3:0]   + 3; 
            if (bcd_out[7:4]   >= 5) bcd_out[7:4]   = bcd_out[7:4]   + 3; 
            if (bcd_out[11:8]  >= 5) bcd_out[11:8]  = bcd_out[11:8]  + 3; 
            if (bcd_out[15:12] >= 5) bcd_out[15:12] = bcd_out[15:12] + 3; 
            
            bcd_out = {bcd_out[14:0], binary_in[i]};
        end
    end
endmodule