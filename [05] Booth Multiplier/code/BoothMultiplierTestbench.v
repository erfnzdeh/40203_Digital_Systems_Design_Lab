`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Self-checking exhaustive testbench.
// Tests every signed 4-bit pair: 16 x 16 = 256 products.
// Includes zero, -1, +7 and the critical -8 boundary automatically.
// -----------------------------------------------------------------------------
module BoothMultiplierTestbench;

    reg        clk;
    reg        str;
    reg  [3:0] multiplicand;
    reg  [3:0] multiplier;
    wire [7:0] result;
    wire       valid;

    integer a;
    integer b;
    integer expected;
    integer errors;
    integer tests;
    integer cycles;

    BoothMultiplier dut (
        .multiplicand (multiplicand),
        .multiplier   (multiplier),
        .clk          (clk),
        .str          (str),
        .result       (result),
        .valid        (valid)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        str          = 1'b0;
        multiplicand = 4'd0;
        multiplier   = 4'd0;
        errors        = 0;
        tests         = 0;

        // Exhaustive signed test: -8 .. +7 for both operands.
        for (a = -8; a <= 7; a = a + 1) begin
            for (b = -8; b <= 7; b = b + 1) begin

                // Apply operands and issue a clean one-cycle start pulse.
                @(negedge clk);
                multiplicand = a[3:0];
                multiplier   = b[3:0];
                str          = 1'b1;

                @(negedge clk);
                str = 1'b0;

                // Wait for completion, with a timeout to catch controller bugs.
                cycles = 0;
                while ((valid !== 1'b1) && (cycles < 12)) begin
                    @(negedge clk);
                    cycles = cycles + 1;
                end

                tests    = tests + 1;
                expected = a * b;

                if (valid !== 1'b1) begin
                    errors = errors + 1;
                    $display("TIMEOUT: %0d * %0d", a, b);
                end
                else if ($signed(result) !== expected) begin
                    errors = errors + 1;
                    $display("FAIL: %0d * %0d => got %0d (0x%02h), expected %0d",
                             a, b, $signed(result), result, expected);
                end
                else begin
                    $display("PASS: %0d * %0d = %0d", a, b, $signed(result));
                end
            end
        end

        $display("--------------------------------------------------");
        $display("Tests  : %0d", tests);
        $display("Errors : %0d", errors);
        if (errors == 0)
            $display("ALL 256 SIGNED 4-BIT TESTS PASSED.");
        else
            $display("TEST FAILED.");
        $display("--------------------------------------------------");

        $stop;
    end

endmodule
