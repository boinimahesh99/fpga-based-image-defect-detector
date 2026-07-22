`timescale 1ns / 1ps
// ============================================================================
// 3. VGA TIMING GENERATOR
// ============================================================================
module vga_timing (
    input clk, reset,
    output reg h_sync_out, v_sync_out,
    output reg [9:0] pixel_x, pixel_y, 
    output video_active, end_of_frame
);
    always @(posedge clk or posedge reset) begin
        if (reset) pixel_x <= 0;
        else pixel_x <= (pixel_x == 799) ? 0 : pixel_x + 1;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) pixel_y <= 0;
        else if (pixel_x == 799) pixel_y <= (pixel_y == 524) ? 0 : pixel_y + 1;
    end

    always @(*) begin
        h_sync_out = (pixel_x >= 656 && pixel_x < 752) ? 0 : 1;
        v_sync_out = (pixel_y >= 490 && pixel_y < 492) ? 0 : 1;
    end

    assign video_active = (pixel_x < 640 && pixel_y < 480);
    assign end_of_frame = (pixel_x == 0 && pixel_y == 481);
endmodule