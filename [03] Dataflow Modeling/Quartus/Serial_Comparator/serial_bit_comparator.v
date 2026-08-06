module serial_bit_comparator (
    input  wire reset,
    input  wire clock,

    input  wire serial_first_bit,
    input  wire serial_second_bit,

    output wire first_is_greater,
    output wire bits_are_equal,
    output wire first_is_less
);

    wire next_greater;
    wire next_equal;
    wire next_less;

    wire master_greater;
    wire master_equal;
    wire master_less;

    assign next_greater =
        first_is_greater |
        (bits_are_equal & serial_first_bit & ~serial_second_bit);

    assign next_equal =
        bits_are_equal &
        ~(serial_first_bit ^ serial_second_bit);

    assign next_less =
        first_is_less |
        (bits_are_equal & ~serial_first_bit & serial_second_bit);

    assign master_greater =
        reset ? 1'b0 :
        (clock ? master_greater : next_greater);

    assign first_is_greater =
        reset ? 1'b0 :
        (clock ? master_greater : first_is_greater);

    assign master_equal =
        reset ? 1'b1 :
        (clock ? master_equal : next_equal);

    assign bits_are_equal =
        reset ? 1'b1 :
        (clock ? master_equal : bits_are_equal);

    assign master_less =
        reset ? 1'b0 :
        (clock ? master_less : next_less);

    assign first_is_less =
        reset ? 1'b0 :
        (clock ? master_less : first_is_less);

endmodule