`timescale 1ns / 1ps
// ============================================================================
// 5. NOISE FILTER (1D Gaussian Approx)
// ============================================================================
module noise_filter (
    input clk,
    input [7:0] pixel_in,
    output [7:0] pixel_out
);
    reg [7:0] p_left = 0, p_center = 0, p_right = 0;

    always @(posedge clk) begin
        p_left <= p_center; p_center <= p_right; p_right <= pixel_in;
    end

    // (left + 2*center + right) / 4 
    wire [9:0] sum = p_left + {p_center, 1'b0} + p_right;
    assign pixel_out = sum[9:2]; 
endmodule 