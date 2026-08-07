module four_bit_comparator (

    // دو عدد چهار بیتی که باید با یکدیگر مقایسه شوند
    input  wire [3:0] first_number,
    input  wire [3:0] second_number,

    // خروجی‌های نهایی مقایسه
    output wire first_is_greater,
    output wire numbers_are_equal,
    output wire first_is_less
);

    // خروجی مرحله مربوط به بیت شماره 3
    wire greater_after_bit3;
    wire equal_after_bit3;
    wire less_after_bit3;

    // خروجی مرحله مربوط به بیت شماره 2
    wire greater_after_bit2;
    wire equal_after_bit2;
    wire less_after_bit2;

    // خروجی مرحله مربوط به بیت شماره 1
    wire greater_after_bit1;
    wire equal_after_bit1;
    wire less_after_bit1;


    //==========================================================
    // مرحله اول: مقایسه MSB یعنی بیت شماره 3
    // قبل از شروع مقایسه فرض می‌کنیم دو عدد مساوی هستند:
    // Greater = 0 , Equal = 1 , Less = 0
    //==========================================================

    compare_stage stage_bit3 (

        .first_bit             (first_number[3]),
        .second_bit            (second_number[3]),

        .greater_from_previous (1'b0),
        .equal_from_previous   (1'b1),
        .less_from_previous    (1'b0),

        .greater_to_next       (greater_after_bit3),
        .equal_to_next         (equal_after_bit3),
        .less_to_next          (less_after_bit3)
    );


    //==========================================================
    // مرحله دوم: مقایسه بیت شماره 2
    // نتیجه مرحله قبلی به این مرحله منتقل می‌شود.
    //==========================================================

    compare_stage stage_bit2 (

        .first_bit             (first_number[2]),
        .second_bit            (second_number[2]),

        .greater_from_previous (greater_after_bit3),
        .equal_from_previous   (equal_after_bit3),
        .less_from_previous    (less_after_bit3),

        .greater_to_next       (greater_after_bit2),
        .equal_to_next         (equal_after_bit2),
        .less_to_next          (less_after_bit2)
    );


    //==========================================================
    // مرحله سوم: مقایسه بیت شماره 1
    //==========================================================

    compare_stage stage_bit1 (

        .first_bit             (first_number[1]),
        .second_bit            (second_number[1]),

        .greater_from_previous (greater_after_bit2),
        .equal_from_previous   (equal_after_bit2),
        .less_from_previous    (less_after_bit2),

        .greater_to_next       (greater_after_bit1),
        .equal_to_next         (equal_after_bit1),
        .less_to_next          (less_after_bit1)
    );


    //==========================================================
    // مرحله چهارم: مقایسه LSB یعنی بیت شماره 0
    // خروجی این مرحله، نتیجه نهایی مقایسه دو عدد است.
    //==========================================================

    compare_stage stage_bit0 (

        .first_bit             (first_number[0]),
        .second_bit            (second_number[0]),

        .greater_from_previous (greater_after_bit1),
        .equal_from_previous   (equal_after_bit1),
        .less_from_previous    (less_after_bit1),

        .greater_to_next       (first_is_greater),
        .equal_to_next         (numbers_are_equal),
        .less_to_next          (first_is_less)
    );

endmodule
