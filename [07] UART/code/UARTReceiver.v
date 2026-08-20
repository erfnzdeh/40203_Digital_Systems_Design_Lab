`timescale 1ns/1ps

module UARTReceiver #(
    parameter integer TICKS_BIT = 2
)(
    input  wire       clk,
    input  wire       rstN,
    input  wire       rx,
    output reg  [6:0] data_rec,
    output reg        data_new_rec,
    output reg        data_correct
);

    localparam [2:0] S_IDLE  = 3'd0;
    localparam [2:0] S_START = 3'd1;
    localparam [2:0] S_DATA  = 3'd2;
    localparam [2:0] S_STOP  = 3'd3;

    reg [2:0] state;
    reg [2:0] bit_index;
    reg [6:0] data_reg;
    reg       parity_received;
    integer   tick_count;

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            state           <= S_IDLE;
            bit_index       <= 3'd0;
            data_reg        <= 7'd0;
            parity_received <= 1'b0;
            tick_count      <= 0;
            data_rec        <= 7'd0;
            data_new_rec    <= 1'b0;
            data_correct    <= 1'b0;
        end else begin
            // Asserted for one clock when a complete frame is received.
            data_new_rec <= 1'b0;

            case (state)
                S_IDLE: begin
                    tick_count <= 0;
                    bit_index  <= 3'd0;

                    // A low level on the idle-high line indicates the start bit.
                    if (rx == 1'b0) begin
                        state      <= S_START;
                        tick_count <= 0;
                    end
                end

                S_START: begin
                    if (tick_count == TICKS_BIT - 1) begin
                        tick_count      <= 0;
                        parity_received <= rx;
                        bit_index       <= 3'd0;
                        state           <= S_DATA;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end

                S_DATA: begin
                    if (tick_count == TICKS_BIT - 1) begin
                        tick_count          <= 0;
                        data_reg[bit_index] <= rx;

                        if (bit_index == 3'd6) begin
                            state <= S_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end

                S_STOP: begin
                    if (tick_count == TICKS_BIT - 1) begin
                        tick_count   <= 0;
                        data_rec     <= data_reg;
                        data_new_rec <= 1'b1;

                        // A frame is valid only if stop=1 and parity matches the data.
                        if ((rx == 1'b1) && ((^data_reg) == parity_received))
                            data_correct <= 1'b1;
                        else
                            data_correct <= 1'b0;

                        state <= S_IDLE;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end

                default: begin
                    state           <= S_IDLE;
                    bit_index       <= 0;
                    tick_count      <= 0;
                    data_new_rec    <= 1'b0;
                    data_correct    <= 1'b0;
                end
            endcase
        end
    end

endmodule
