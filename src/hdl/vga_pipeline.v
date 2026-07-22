`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2026 14:07:59
// Design Name: 
// Module Name: vga_pipeline
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// ============================================================================
// 2. VGA RENDERER & PIPELINE (Beginner Friendly Version)
// ============================================================================
module vga_renderer (
    input clk,
    input h_sync_in, v_sync_in, video_active_in, draw_ref_in, draw_test_in,
    input [7:0] ref_pixel, test_pixel,
    input is_defect, prog_mode,
    
    output h_sync_out, v_sync_out,
    output reg [3:0] vga_r, vga_g, vga_b,
    output draw_test_out
);
    // --------------------------------------------------------
    // STAGE 1: Wait for BRAM to latch the input address
    // --------------------------------------------------------
    reg h_sync_stage1, v_sync_stage1, video_stage1, ref_stage1, test_stage1;
    always @(posedge clk) begin
        h_sync_stage1 <= h_sync_in;
        v_sync_stage1 <= v_sync_in;
        video_stage1  <= video_active_in;
        ref_stage1    <= draw_ref_in;
        test_stage1   <= draw_test_in;
    end

    // --------------------------------------------------------
    // STAGE 2: Wait for BRAM to output the pixel data
    // --------------------------------------------------------
    reg h_sync_stage2, v_sync_stage2, video_stage2, ref_stage2, test_stage2;
    always @(posedge clk) begin
        h_sync_stage2 <= h_sync_stage1;
        v_sync_stage2 <= v_sync_stage1;
        video_stage2  <= video_stage1;
        ref_stage2    <= ref_stage1;
        test_stage2   <= test_stage1;
    end

    // --------------------------------------------------------
    // STAGE 3: Wait for the Spatial Noise Filter math to finish
    // --------------------------------------------------------
    reg h_sync_stage3, v_sync_stage3, video_stage3, ref_stage3, test_stage3;
    always @(posedge clk) begin
        h_sync_stage3 <= h_sync_stage2;
        v_sync_stage3 <= v_sync_stage2;
        video_stage3  <= video_stage2;
        ref_stage3    <= ref_stage2;
        test_stage3   <= test_stage2;
    end

    // Map the final 3rd-stage delayed signals to our outputs
    assign h_sync_out    = h_sync_stage3;
    assign v_sync_out    = v_sync_stage3;
    assign draw_test_out = test_stage3; 

    // --------------------------------------------------------
    // Output Color Logic (Combinational)
    // --------------------------------------------------------
    always @(*) begin
        // Default everything to black
        vga_r = 4'h0; 
        vga_g = 4'h0; 
        vga_b = 4'h0; 
        
        // Only draw colors if we are in the active visible area of the monitor
        if (video_stage3 == 1'b1) begin
            
            if (ref_stage3 == 1'b1) begin
                // We are inside the Left Box. Draw the pure grayscale reference pixel.
                vga_r = ref_pixel[7:4]; 
                vga_g = ref_pixel[7:4]; 
                vga_b = ref_pixel[7:4];
                
            end else if (test_stage3 == 1'b1) begin
                // We are inside the Right Box. 
                // If a defect is found AND we are not programming, highlight it red!
                if (is_defect == 1'b1 && prog_mode == 1'b0) begin
                    vga_r = 4'hF; // Pure Red
                    vga_g = 4'h0;
                    vga_b = 4'h0;
                end else begin
                    // Otherwise, just draw the normal grayscale test pixel.
                    vga_r = test_pixel[7:4]; 
                    vga_g = test_pixel[7:4]; 
                    vga_b = test_pixel[7:4];
                end
            end
            
        end
    end
endmodule
