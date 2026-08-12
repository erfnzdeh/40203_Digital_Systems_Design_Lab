// -----------------------------------------------------------------------------
// Control Unit for the 4-bit variable-shift Booth multiplier.
//
// The controller performs:
//   START/LOAD -> ARITHMETIC -> VARIABLE SHIFT -> ... -> DONE
//
// booth_bits is the number of adjacent equal multiplier bits that may be
// consumed in the current Booth step.  It is limited by the number of bits
// still left to process, so the final shift never passes the 4-bit boundary.
// -----------------------------------------------------------------------------
module BoothMultiplierControlUnit(
    input  wire [3:0] multiplier,
    input  wire       clk,
    input  wire       str,
    output wire       valid,
    output wire       load,
    output wire       arth,
    output wire       shiftRight,
    output wire [2:0] booth_bits
);

    localparam [2:0] STATE_IDLE  = 3'd0;
    localparam [2:0] STATE_ARITH = 3'd1;
    localparam [2:0] STATE_SHIFT = 3'd2;
    localparam [2:0] STATE_DONE  = 3'd3;

    reg [2:0] state;
    reg [2:0] bits_remaining;

    // str itself is the synchronous load enable.  This avoids dependence on an
    // uninitialized state register at power-up: one asserted start edge fully
    // initializes both the control path and the datapath.
    assign load       = str;
    assign arth       = (!str) && (state == STATE_ARITH);
    assign shiftRight = (!str) && (state == STATE_SHIFT);
    assign valid      = (!str) && (state == STATE_DONE);

    // Find the first transition between neighboring bits of Q, scanning from
    // the LSB upward.  The forced MSB marker guarantees a value in 1..4.
    // Examples:
    //   4'b0011 -> 2  (two adjacent 1s can be consumed)
    //   4'b0000 -> 4  (four adjacent 0s can be consumed)
    //   4'b1111 -> 4  (four adjacent 1s can be consumed)
    wire [3:0] differences;
    reg  [2:0] rightMost;
    integer i;

    assign differences = (multiplier ^ (multiplier >> 1)) | 4'b1000;

    always @(*) begin
        rightMost = 3'd0;
        for (i = 1; i <= 4; i = i + 1) begin
            if (differences[i-1] && (rightMost == 3'd0))
                rightMost = i;
        end
    end

    assign booth_bits = (bits_remaining < rightMost) ? bits_remaining : rightMost;

    always @(posedge clk) begin
        if (str) begin
            state          <= STATE_ARITH;
            bits_remaining <= 3'd4;
        end
        else begin
            case (state)
                STATE_ARITH: begin
                    state <= STATE_SHIFT;
                end

                STATE_SHIFT: begin
                    if (bits_remaining <= booth_bits) begin
                        bits_remaining <= 3'd0;
                        state          <= STATE_DONE;
                    end
                    else begin
                        bits_remaining <= bits_remaining - booth_bits;
                        state          <= STATE_ARITH;
                    end
                end

                STATE_DONE: begin
                    state <= STATE_DONE;
                end

                default: begin
                    // Safe idle behavior before the first start pulse.
                    state          <= STATE_IDLE;
                    bits_remaining <= 3'd0;
                end
            endcase
        end
    end

endmodule
