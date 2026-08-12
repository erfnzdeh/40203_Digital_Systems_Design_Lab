// -----------------------------------------------------------------------------
// Datapath for the 4-bit signed variable-shift Booth multiplier.
//
// Key correction versus the original implementation:
// A is 5 bits, not 4 bits.  M is sign-extended to 5 bits as well.  This guard
// bit is required for the most-negative 4-bit value (-8 = 4'b1000), because
// +8 cannot be represented in a signed 4-bit register during Booth subtraction.
// -----------------------------------------------------------------------------
module BoothMultiplierDatapath(
    input  wire [3:0] multiplicand,
    input  wire [3:0] multiplier,
    input  wire       shiftRight,
    input  wire       load,
    input  wire       arth,
    input  wire [2:0] booth_bits,
    input  wire       clk,
    output wire [3:0] result,
    output wire [3:0] new_multiplier
);

    // A and M use one extra sign/guard bit.
    reg signed [4:0] accumulator;
    reg signed [4:0] temp_multiplicand;
    reg        [3:0] q_reg;
    reg              q_minus_one;

    // Treat the complete Booth register as one signed quantity so that >>>
    // replicates the sign bit of A during a variable-length arithmetic shift.
    wire signed [9:0] booth_register;
    assign booth_register = $signed({accumulator, q_reg, q_minus_one});

    // Preserve the original module interface: high product nibble + Q nibble.
    assign result         = accumulator[3:0];
    assign new_multiplier = q_reg;

    always @(posedge clk) begin
        if (load) begin
            accumulator       <= 5'sd0;
            temp_multiplicand <= {multiplicand[3], multiplicand};
            q_reg             <= multiplier;
            q_minus_one       <= 1'b0;
        end
        else if (arth) begin
            case ({q_reg[0], q_minus_one})
                2'b01: accumulator <= accumulator + temp_multiplicand;
                2'b10: accumulator <= accumulator - temp_multiplicand;
                default: accumulator <= accumulator;
            endcase
        end
        else if (shiftRight) begin
            {accumulator, q_reg, q_minus_one} <= booth_register >>> booth_bits;
        end
    end

endmodule
