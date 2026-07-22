`timescale 1ns / 1ps
// ============================================================================
// 1. TOP LEVEL MODULE
// ============================================================================
module defect_detector_top #(
    parameter MAX_DEFECTS         = 16'h0050, // BCD format (e.g., 50 defects)
    parameter THRESHOLD           = 8'd15,    // Noise tolerance threshold
    parameter SYS_CLK_FREQ        = 25000000, 
    parameter UART_BAUD_RATE      = 115200
)(
    input clk_100MHz,            
    input reset,
    input uart_rx_pin,           
    input sw_program_mode,       // High = Program RAM, Low = Run Defect Detection
    
    // Hardware Outputs
    output pmod_trigger_robot,   
    output led_green_pass,       
    output led_red_fail,         
    
    // VGA Outputs 
    output [3:0] vga_r, vga_g, vga_b,
    output h_sync, v_sync,
    
    // 7-Segment Outputs
    output [6:0] segments,
    output [7:0] anodes       
);

    wire clk_25MHz, clock_locked;
    wire sys_reset = reset | ~clock_locked; 

    // --- Clock Generation (Vivado IP) ---
    clk_wiz_0 clock_generator (
        .clk_in1(clk_100MHz),
        .reset(reset),
        .clk_out1(clk_25MHz),
        .locked(clock_locked)
    );

    // --- VGA Timing & Layout ---
    wire orig_h_sync, orig_v_sync, orig_video_active, end_of_frame;
    wire [9:0] pixel_x, pixel_y;

    vga_timing timing_inst (
        .clk(clk_25MHz),
        .reset(sys_reset),
        .h_sync_out(orig_h_sync),
        .v_sync_out(orig_v_sync),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(orig_video_active),
        .end_of_frame(end_of_frame)
    );

    // Box bounds and Memory Mapping
    wire y_in_bounds = (pixel_y >= 128 && pixel_y < 256);
    wire draw_ref    = (y_in_bounds && (pixel_x >= 128 && pixel_x < 256));
    wire draw_test   = (y_in_bounds && (pixel_x >= 384 && pixel_x < 512));
    
    wire [13:0] mem_read_addr = (draw_ref || draw_test) ? {pixel_y[6:0], pixel_x[6:0]} : 14'd0;

    // --- UART Receiver ---
    wire [7:0] uart_byte;
    wire uart_valid;
    reg [13:0] mem_write_addr;

    uart_rx #(.CLK_FREQ(SYS_CLK_FREQ), .BAUD_RATE(UART_BAUD_RATE)) pc_receiver (
        .clk(clk_25MHz),
        .reset(sys_reset),
        .rx_pin(uart_rx_pin),
        .data(uart_byte),
        .valid(uart_valid)
    );

    always @(posedge clk_25MHz or posedge sys_reset) begin
        if (sys_reset || !sw_program_mode) mem_write_addr <= 0;
        else if (uart_valid && sw_program_mode) mem_write_addr <= mem_write_addr + 1;
    end

    // --- Memory (Vivado BRAM IPs) ---
    wire [7:0] raw_ref_pixel, raw_test_pixel;
    
    blk_mem_gen_ref ref_rom (
        .clka(clk_25MHz),
        .ena(1'b1),            
        .addra(mem_read_addr),
        .douta(raw_ref_pixel)
    );

    blk_mem_gen_test test_ram (
        .clka(clk_25MHz),
        .ena(sw_program_mode),       
        .wea(uart_valid),           
        .addra(mem_write_addr),    
        .dina(uart_byte),            
        .clkb(clk_25MHz),
        .enb(1'b1),                      
        .addrb(mem_read_addr), 
        .doutb(raw_test_pixel)   
    );

    // --- Spatial Noise Filters (DSP) ---
    wire [7:0] smooth_ref_pixel, smooth_test_pixel;

    noise_filter filter_ref  (.clk(clk_25MHz), .pixel_in(raw_ref_pixel),  .pixel_out(smooth_ref_pixel));
    noise_filter filter_test (.clk(clk_25MHz), .pixel_in(raw_test_pixel), .pixel_out(smooth_test_pixel));

    // --- Defect Detection & Counting Logic ---
    wire is_defect;
    wire draw_test_delayed; 
    wire [13:0] raw_binary_defects;
    wire [15:0] bcd_formatted_defects;

    // 1. High-Speed Binary Counter
    defect_detector #(.THRESHOLD(THRESHOLD)) detector_inst (
        .clk(clk_25MHz),
        .reset(sys_reset),
        .ref_pixel(smooth_ref_pixel),      
        .test_pixel(smooth_test_pixel),    
        .pixel_is_valid(draw_test_delayed), 
        .end_of_frame(end_of_frame),
        .is_defect(is_defect),
        .final_binary_count(raw_binary_defects)
    );

    // 2. Combinational Binary to BCD Converter
    binary_to_bcd bcd_converter (
        .binary_in(raw_binary_defects),
        .bcd_out(bcd_formatted_defects)
    );

    // --- VGA Pipeline & Renderer ---
    vga_renderer renderer_inst (
        .clk(clk_25MHz),
        .h_sync_in(orig_h_sync),      .v_sync_in(orig_v_sync),
        .video_active_in(orig_video_active),
        .draw_ref_in(draw_ref),       .draw_test_in(draw_test),
        .ref_pixel(smooth_ref_pixel), .test_pixel(smooth_test_pixel),
        .is_defect(is_defect),        .prog_mode(sw_program_mode),
        
        .h_sync_out(h_sync),          .v_sync_out(v_sync),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .draw_test_out(draw_test_delayed)
    );

    // --- Seven Segment Controller ---
    wire [3:0] lower_anodes;
    seven_seg_driver screen_driver (
        .clk(clk_25MHz), 
        .reset(sys_reset),
        .bcd_count(bcd_formatted_defects),
        .segments(segments),
        .anodes(lower_anodes)
    );
    assign anodes = {4'b1111, lower_anodes};

    // --- Robotic IO ---
    wire board_rejected = (bcd_formatted_defects > MAX_DEFECTS);
    assign pmod_trigger_robot = (board_rejected && !sw_program_mode);
    assign led_red_fail       = (board_rejected && !sw_program_mode); 
    assign led_green_pass     = (!board_rejected && !sw_program_mode);

endmodule

