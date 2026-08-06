`timescale 1ns/1ps

module serial_bit_comparator_tb;

    reg clock;
    reg reset;

    reg serial_first_bit;
    reg serial_second_bit;

    wire first_is_greater;
    wire bits_are_equal;
    wire first_is_less;

    integer error_count;

    serial_bit_comparator dut (
        .reset             (reset),
        .clock             (clock),
        .serial_first_bit  (serial_first_bit),
        .serial_second_bit (serial_second_bit),
        .first_is_greater  (first_is_greater),
        .bits_are_equal    (bits_are_equal),
        .first_is_less     (first_is_less)
    );

	 
    initial begin
        clock = 1'b0;

        forever begin
            #5 clock = ~clock;
        end
    end
	 
    task reset_comparator;
        begin
            reset             = 1'b1;
            serial_first_bit  = 1'b0;
            serial_second_bit = 1'b0;

            #2;

            if (
                first_is_greater !== 1'b0 ||
                bits_are_equal   !== 1'b1 ||
                first_is_less    !== 1'b0
            ) begin
                error_count = error_count + 1;

                $display(
                    "RESET ERROR: greater=%b equal=%b less=%b",
                    first_is_greater,
                    bits_are_equal,
                    first_is_less
                );
            end

            @(negedge clock);
            #1;
            reset = 1'b0;
        end
    endtask

    task compare_words;

        input [3:0] first_word;
        input [3:0] second_word;

        integer bit_index;

        reg expected_greater;
        reg expected_equal;
        reg expected_less;

        begin
            expected_greater = 1'b0;
            expected_equal   = 1'b1;
            expected_less    = 1'b0;

            reset_comparator;

            $display(
                "Testing first=%b second=%b",
                first_word,
                second_word
            );

            for (
                bit_index = 3;
                bit_index >= 0;
                bit_index = bit_index - 1
            ) begin

                @(negedge clock);

                serial_first_bit  = first_word[bit_index];
                serial_second_bit = second_word[bit_index];

                if (expected_equal == 1'b1) begin

                    if (first_word[bit_index] > second_word[bit_index]) begin
                        expected_greater = 1'b1;
                        expected_equal   = 1'b0;
                        expected_less    = 1'b0;
                    end
                    else if (first_word[bit_index] < second_word[bit_index]) begin
                        expected_greater = 1'b0;
                        expected_equal   = 1'b0;
                        expected_less    = 1'b1;
                    end

                end

                @(posedge clock);
                #1;

                if (
                    first_is_greater !== expected_greater ||
                    bits_are_equal   !== expected_equal   ||
                    first_is_less    !== expected_less
                ) begin

                    error_count = error_count + 1;

                    $display(
                        "ERROR at bit %0d: A_bit=%b B_bit=%b | actual=%b%b%b expected=%b%b%b",
                        bit_index,
                        serial_first_bit,
                        serial_second_bit,
                        first_is_greater,
                        bits_are_equal,
                        first_is_less,
                        expected_greater,
                        expected_equal,
                        expected_less
                    );

                end
                else begin

                    $display(
                        "Bit %0d passed: A_bit=%b B_bit=%b result=%b%b%b",
                        bit_index,
                        serial_first_bit,
                        serial_second_bit,
                        first_is_greater,
                        bits_are_equal,
                        first_is_less
                    );

                end

            end
        end
    endtask

    initial begin

        reset             = 1'b1;
        serial_first_bit  = 1'b0;
        serial_second_bit = 1'b0;
        error_count       = 0;

        $display("============================================");
        $display("Starting serial comparator simulation");
        $display("============================================");

        compare_words(4'b1100, 4'b1100);

        compare_words(4'b1000, 4'b0111);

        compare_words(4'b0100, 4'b0111);

        compare_words(4'b1011, 4'b1001);

        compare_words(4'b0011, 4'b0100);

        compare_words(4'b1011, 4'b1010);

        $display("============================================");

        if (error_count == 0) begin
            $display("ALL SERIAL COMPARATOR TESTS PASSED");
        end
        else begin
            $display(
                "SERIAL SIMULATION FAILED: %0d errors",
                error_count
            );
        end

        $display("============================================");

        $stop;

    end

endmodule