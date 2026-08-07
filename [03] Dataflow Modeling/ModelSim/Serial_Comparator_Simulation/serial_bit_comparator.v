module serial_bit_comparator (

    // ورودی Reset برای بازگرداندن مدار به حالت اولیه
    input wire reset,

    // ورودی کلاک
    input wire clock,

    // بیت سریال عدد اول
    input wire serial_first_bit,

    // بیت سریال عدد دوم
    input wire serial_second_bit,

    // خروجی‌های مقایسه
    output wire first_is_greater,
    output wire bits_are_equal,
    output wire first_is_less
);


    //==========================================================
    // این سه سیگنال نتیجه جدید مقایسه را
    // با توجه به بیت فعلی مشخص می‌کنند.
    //==========================================================

    wire next_greater;
    wire next_equal;
    wire next_less;


    //==========================================================
    // سیگنال‌های میانی برای ساخت حافظه Master-Slave
    //==========================================================

    wire master_greater;
    wire master_equal;
    wire master_less;


    //==========================================================
    // محاسبه وضعیت Greater
    //
    // اگر قبلاً عدد اول بزرگ‌تر شده باشد، نتیجه حفظ می‌شود.
    // اگر هنوز مساوی باشند و بیت اول 1 و بیت دوم 0 باشد،
    // عدد اول بزرگ‌تر می‌شود.
    //==========================================================

    assign next_greater =
        first_is_greater |
        (bits_are_equal &
         serial_first_bit &
         ~serial_second_bit);


    //==========================================================
    // محاسبه وضعیت Equal
    //
    // فقط زمانی مساوی باقی می‌مانند که:
    // 1) قبلاً مساوی بوده باشند.
    // 2) دو بیت فعلی نیز مساوی باشند.
    //==========================================================

    assign next_equal =
        bits_are_equal &
        ~(serial_first_bit ^ serial_second_bit);


    //==========================================================
    // محاسبه وضعیت Less
    //
    // اگر قبلاً عدد اول کوچک‌تر شده باشد، نتیجه حفظ می‌شود.
    // اگر هنوز مساوی باشند و بیت اول 0 و بیت دوم 1 باشد،
    // عدد اول کوچک‌تر می‌شود.
    //==========================================================

    assign next_less =
        first_is_less |
        (bits_are_equal &
         ~serial_first_bit &
         serial_second_bit);


    //==========================================================
    // حافظه مربوط به حالت Greater
    // دو Latch به صورت Master-Slave استفاده شده‌اند.
    //
    // در Reset:
    // Greater باید صفر شود.
    //==========================================================

    assign master_greater =
        reset ? 1'b0 :
        (clock ? master_greater : next_greater);

    assign first_is_greater =
        reset ? 1'b0 :
        (clock ? master_greater : first_is_greater);


    //==========================================================
    // حافظه مربوط به حالت Equal
    //
    // در Reset:
    // Equal برابر یک قرار می‌گیرد،
    // زیرا هنوز هیچ بیتی متفاوت مشاهده نشده است.
    //==========================================================

    assign master_equal =
        reset ? 1'b1 :
        (clock ? master_equal : next_equal);

    assign bits_are_equal =
        reset ? 1'b1 :
        (clock ? master_equal : bits_are_equal);


    //==========================================================
    // حافظه مربوط به حالت Less
    //
    // در Reset:
    // Less باید صفر شود.
    //==========================================================

    assign master_less =
        reset ? 1'b0 :
        (clock ? master_less : next_less);

    assign first_is_less =
        reset ? 1'b0 :
        (clock ? master_less : first_is_less);

endmodule
