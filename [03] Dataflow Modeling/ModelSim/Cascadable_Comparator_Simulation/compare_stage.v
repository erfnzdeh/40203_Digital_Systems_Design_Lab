module compare_stage (
    input  wire first_bit,
    input  wire second_bit,

    input  wire greater_from_previous,
    input  wire equal_from_previous,
    input  wire less_from_previous,

    output wire greater_to_next,
    output wire equal_to_next,
    output wire less_to_next
);

    assign greater_to_next =
        greater_from_previous |
        (equal_from_previous & first_bit & ~second_bit);

    assign equal_to_next =
        equal_from_previous & ~(first_bit ^ second_bit);

    assign less_to_next =
        less_from_previous |
        (equal_from_previous & ~first_bit & second_bit);

endmodule