`timescale 1ns / 1ps
// ============================================================================
// 6. DEFECT DETECTOR (Minimal Binary Counter)
// ============================================================================
module defect_detector #(parameter THRESHOLD = 15)(
    input clk, reset, pixel_is_valid, end_of_frame,
    input [7:0] ref_pixel, test_pixel,
    output is_defect,
    output reg [13:0] final_binary_count
);
    wire [7:0] diff = (ref_pixel > test_pixel) ? (ref_pixel - test_pixel) : (test_pixel - ref_pixel);
    assign is_defect = (diff > THRESHOLD);

    reg [13:0] live_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            live_counter <= 0;
            final_binary_count <= 0;
        end else if (end_of_frame) begin
            final_binary_count <= live_counter; 
            live_counter <= 0;                  
        end else if (pixel_is_valid && is_defect) begin
            live_counter <= live_counter + 1;   
        end
    end
endmodule