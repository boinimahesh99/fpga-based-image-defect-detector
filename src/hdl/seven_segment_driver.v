`timescale 1ns / 1ps
// ============================================================================
// 8. SEVEN SEGMENT DRIVER
// ============================================================================
module seven_seg_driver (
    input clk, reset,
    input [15:0] bcd_count,
    output reg [6:0] segments,
    output reg [3:0] anodes
);
    reg [17:0] refresh_counter; 
    always @(posedge clk or posedge reset) begin
        if(reset) refresh_counter <= 0; else refresh_counter <= refresh_counter + 1;
    end

    wire [1:0] active_digit = refresh_counter[17:16];
    reg [3:0] current_val;

    always @(*) begin
        case(active_digit)
            2'b00: begin anodes = 4'b1110; current_val = bcd_count[3:0];   end 
            2'b01: begin anodes = 4'b1101; current_val = bcd_count[7:4];   end 
            2'b10: begin anodes = 4'b1011; current_val = bcd_count[11:8];  end 
            2'b11: begin anodes = 4'b0111; current_val = bcd_count[15:12]; end 
        endcase
    end

    always @(*) begin
        case(current_val)
            4'd0: segments = 7'b1000000; 4'd1: segments = 7'b1111001;
            4'd2: segments = 7'b0100100; 4'd3: segments = 7'b0110000;
            4'd4: segments = 7'b0011001; 4'd5: segments = 7'b0010010;
            4'd6: segments = 7'b0000010; 4'd7: segments = 7'b1111000;
            4'd8: segments = 7'b0000000; 4'd9: segments = 7'b0010000;
            default: segments = 7'b1111111; 
        endcase
    end
endmodule
