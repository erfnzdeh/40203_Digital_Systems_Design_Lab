`timescale 1ns/1ps

module four_bit_comparator_tb;

    reg  [3:0] test_first_number;
    reg  [3:0] test_second_number;

    wire result_greater;
    wire result_equal;
    wire result_less;

    integer first_value;
    integer second_value;
    integer error_count;

    four_bit_comparator dut (
        .first_number      (test_first_number),
        .second_number     (test_second_number),
        .first_is_greater  (result_greater),
        .numbers_are_equal (result_equal),
        .first_is_less     (result_less)
    );

    initial begin

        test_first_number  = 4'b0000;
        test_second_number = 4'b0000;
        error_count        = 0;

        $display("--------------------------------------------");
        $display("Starting exhaustive comparator simulation");
        $display("--------------------------------------------");

        for (first_value = 0; first_value < 16; first_value = first_value + 1) begin
            for (second_value = 0; second_value < 16; second_value = second_value + 1) begin

                test_first_number  = first_value;
                test_second_number = second_value;

                #10;

                if (
                    (result_greater !== (test_first_number > test_second_number)) ||
                    (result_equal   !== (test_first_number == test_second_number)) ||
                    (result_less    !== (test_first_number < test_second_number))
                ) begin

                    error_count = error_count + 1;

                    $display(
                        "ERROR: first=%d second=%d | greater=%b equal=%b less=%b",
                        test_first_number,
                        test_second_number,
                        result_greater,
                        result_equal,
                        result_less
                    );

                end

            end
        end

        if (error_count == 0) begin
            $display("--------------------------------------------");
            $display("ALL 256 TEST CASES PASSED SUCCESSFULLY");
            $display("--------------------------------------------");
        end
        else begin
            $display("--------------------------------------------");
            $display("SIMULATION FAILED: %d errors detected", error_count);
            $display("--------------------------------------------");
        end

        $stop;

    end

endmodule