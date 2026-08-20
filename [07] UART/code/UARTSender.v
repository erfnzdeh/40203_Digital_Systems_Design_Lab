`timescale 1ns/1ps

module UARTSender #(
    parameter integer TICKS_BIT = 2
)(
    input  wire       clk,
    input  wire       rstN,
    input  wire       data_new,
    input  wire [6:0] data_send,
    output reg        tx,
    output reg        busy
);

    localparam [2:0] S_IDLE   = 3'd0;
    localparam [2:0] S_START  = 3'd1;
    localparam [2:0] S_PARITY = 3'd2;
    localparam [2:0] S_DATA   = 3'd3;
    localparam [2:0] S_STOP   = 3'd4;

    reg [2:0] state;
    reg [2:0] bit_index;
    reg [6:0] data_reg;
    reg       parity_reg;
    integer   tick_count;

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            state      <= S_IDLE;
            bit_index  <= 3'd0;
            data_reg   <= 7'd0;
            parity_reg <= 1'b0;
            tick_count <= 0;
            tx         <= 1'b1;
            busy       <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx         <= 1'b1;
                    busy       <= 1'b0;
                    tick_count <= 0;
                    bit_index  <= 3'd0;

                    // A new request is accepted only in IDLE.
                    if (data_new) begin
                        data_reg   <= data_send;
                        parity_reg <= ^data_send;
                        tx         <= 1'b0;
                        busy       <= 1'b1;
                        state      <= S_START;
                    end
                end

                S_START: begin
                    busy <= 1'b1;
                    if (tick_count == TICKS_BIT - 1) begin
                        tick_count <= 0;
                        tx         <= parity_reg;
                        state      <= S_PARITY;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end

                S_PARITY: begin
                    busy <= 1'b1;
                    if (tick_count == TICKS_BIT - 1) begin
                        tick_count <= 0;
                        bit_index  <= 3'd0;
                        tx         <= data_reg[0];
                        state      <= S_DATA;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end

                S_DATA: begin
                    busy <= 1'b1;
                    if (tick_count == TICKS_BIT - 1) begin
                        tick_count <= 0;

                        // Data bits are transmitted LSB first: D0 through D6.
                        if (bit_index == 3'd6) begin
                            tx    <= 1'b1;
                            state <= S_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            tx        <= data_reg[bit_index + 1'b1];
                        end
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end

                S_STOP: begin
                    busy <= 1'b1;
                    tx   <= 1'b1;
                    if (tick_count == TICKS_BIT - 1) begin
                        tick_count <= 0;
                        busy       <= 1'b0;
                        state      <= S_IDLE;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end

                default: begin
                    state      <= S_IDLE;
                    tick_count <= 0;
                    bit_index  <= 0;
                    tx         <= 1'b1;
                    busy       <= 1'b0;
                end
            endcase
        end
    end

endmodule
