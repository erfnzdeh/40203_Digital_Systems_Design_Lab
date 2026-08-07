module compare_stage (

    // بیت فعلی از عدد اول و دوم
    input  wire first_bit,
    input  wire second_bit,

    // نتیجه‌ای که از طبقه قبلی دریافت می‌شود
    input  wire greater_from_previous,
    input  wire equal_from_previous,
    input  wire less_from_previous,

    // نتیجه‌ای که به طبقه بعدی ارسال می‌شود
    output wire greater_to_next,
    output wire equal_to_next,
    output wire less_to_next
);

    // اگر قبلاً عدد اول بزرگ‌تر بوده، نتیجه حفظ می‌شود.
    // همچنین اگر بیت‌های قبلی مساوی بوده‌اند و بیت اول 1 و بیت دوم 0 باشد،
    // عدد اول بزرگ‌تر خواهد بود.
    assign greater_to_next =
        greater_from_previous |
        (equal_from_previous & first_bit & ~second_bit);

    // فقط وقتی حالت مساوی حفظ می‌شود که
    // قبلاً مساوی بوده‌اند و دو بیت فعلی نیز مساوی باشند.
    assign equal_to_next =
        equal_from_previous &
        ~(first_bit ^ second_bit);

    // اگر قبلاً عدد اول کوچک‌تر بوده، نتیجه حفظ می‌شود.
    // همچنین اگر قبلاً مساوی بوده‌اند و بیت اول 0 و بیت دوم 1 باشد،
    // عدد اول کوچک‌تر خواهد بود.
    assign less_to_next =
        less_from_previous |
        (equal_from_previous & ~first_bit & second_bit);

endmodule
