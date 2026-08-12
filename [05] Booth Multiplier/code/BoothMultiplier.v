// -----------------------------------------------------------------------------
// 4-bit signed Booth multiplier with variable multi-bit arithmetic shifts.
// Datapath and Control Unit are intentionally kept as separate modules.
// Inputs and output are two's-complement signed values:
//   multiplicand, multiplier : 4-bit signed (-8 .. +7)
//   result                   : 8-bit signed (-64 .. +56)
//
// Start protocol:
//   Assert str for at least one rising clock edge.
//   Deassert str afterwards. valid goes high when result is ready.
// -----------------------------------------------------------------------------
module BoothMultiplier(
    input  wire [3:0] multiplicand,
    input  wire [3:0] multiplier,
    input  wire       clk,
    input  wire       str,
    output wire [7:0] result,
    output wire       valid
);

    wire       shiftRight;
    wire       load;
    wire       arth;
    wire [2:0] booth_bits;
    wire [3:0] acc_low;
    wire [3:0] q_value;

    BoothMultiplierDatapath datapath (
        .multiplicand   (multiplicand),
        .multiplier     (multiplier),
        .shiftRight     (shiftRight),
        .load           (load),
        .arth           (arth),
        .booth_bits     (booth_bits),
        .clk            (clk),
        .result         (acc_low),
        .new_multiplier (q_value)
    );

    BoothMultiplierControlUnit control (
        .multiplier (q_value),
        .clk        (clk),
        .str        (str),
        .valid      (valid),
        .load       (load),
        .arth       (arth),
        .shiftRight (shiftRight),
        .booth_bits (booth_bits)
    );

    // The internal accumulator has one guard/sign bit.  The guard bit is
    // discarded only at the final 8-bit product interface.
    assign result = {acc_low, q_value};

endmodule
