`timescale 1ns / 1ps
// ============================================================================
// 4. UART RECEIVER (Beginner Friendly Version)
// ============================================================================
module uart_rx #(parameter CLK_FREQ = 25000000, parameter BAUD_RATE = 115200)(
    input clk, reset, rx_pin,
    output reg [7:0] data,
    output reg valid
);
    // Calculate how many clock cycles equal one UART bit
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // Explicit names for our State Machine steps
    localparam STATE_WAIT_FOR_START = 2'd0;
    localparam STATE_READ_START_BIT = 2'd1;
    localparam STATE_READ_DATA_BITS = 2'd2;
    localparam STATE_READ_STOP_BIT  = 2'd3;

    reg [1:0] state;
    reg [15:0] timer;
    reg [2:0] bit_index;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STATE_WAIT_FOR_START; 
            timer <= 0; 
            bit_index <= 0; 
            data <= 0; 
            valid <= 0;
        end else begin
            // Default condition: data is not ready yet
            valid <= 0; 
            
            case (state)
                STATE_WAIT_FOR_START: begin
                    timer <= 0; 
                    bit_index <= 0; 
                    // UART line idles HIGH. A drop to LOW means a transmission is starting.
                    if (rx_pin == 1'b0) begin
                        state <= STATE_READ_START_BIT;
                    end
                end
                
                STATE_READ_START_BIT: begin
                    // Wait until we are exactly in the MIDDLE of the start bit.
                    // This ensures we sample the line when the voltage is most stable.
                    if (timer == (CLKS_PER_BIT / 2)) begin
                        timer <= 0;
                        // Double check the line is still LOW. If it's HIGH, it was just a noise glitch.
                        if (rx_pin == 1'b0) begin
                            state <= STATE_READ_DATA_BITS;
                        end else begin
                            state <= STATE_WAIT_FOR_START;
                        end
                    end else begin
                        timer <= timer + 1;
                    end
                end
                
                STATE_READ_DATA_BITS: begin
                    // Wait one full bit-width of time to reach the middle of the next data bit
                    if (timer < CLKS_PER_BIT - 1) begin
                        timer <= timer + 1;
                    end else begin
                        timer <= 0; 
                        
                        // Sample the bit and save it into our 8-bit register
                        data[bit_index] <= rx_pin;
                        
                        // Move to the next bit, or finish if we've read all 8 bits (0 through 7)
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STATE_READ_STOP_BIT;
                        end
                    end
                end
                
                STATE_READ_STOP_BIT: begin
                    // Wait one full bit-width for the stop bit to finish
                    if (timer < CLKS_PER_BIT - 1) begin
                        timer <= timer + 1;
                    end else begin
                        // Tell the rest of the FPGA that a full, valid byte is ready!
                        valid <= 1'b1; 
                        state <= STATE_WAIT_FOR_START;
                    end
                end
            endcase
        end
    end
endmodule
