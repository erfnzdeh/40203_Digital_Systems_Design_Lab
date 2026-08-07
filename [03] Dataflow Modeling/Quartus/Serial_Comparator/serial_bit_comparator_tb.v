`timescale 1ns/1ps

module serial_bit_comparator_tb;

    // ورودی کلاک
    reg clock;

    // ورودی Reset
    reg reset;

    // بیت سریال عدد اول و دوم
    reg serial_first_bit;
    reg serial_second_bit;

    // خروجی‌های مدار
    wire first_is_greater;
    wire bits_are_equal;
    wire first_is_less;

    // تعداد خطاهای شبیه‌سازی
    integer error_count;


    //==========================================================
    // نمونه‌سازی مدار اصلی
    // DUT = Design Under Test
    //==========================================================

    serial_bit_comparator dut (

        .reset             (reset),
        .clock             (clock),

        .serial_first_bit  (serial_first_bit),
        .serial_second_bit (serial_second_bit),

        .first_is_greater  (first_is_greater),
        .bits_are_equal    (bits_are_equal),
        .first_is_less     (first_is_less)
    );


    //==========================================================
    // تولید سیگنال کلاک
    //
    // هر 5 ns مقدار کلاک معکوس می‌شود.
    // بنابراین دوره کامل کلاک برابر 10 ns است.
    //==========================================================

    initial begin

        clock = 1'b0;

        forever begin
            #5 clock = ~clock;
        end

    end


    //==========================================================
    // Task مربوط به Reset کردن مدار
    //
    // بعد از Reset انتظار داریم:
    // Greater = 0
    // Equal   = 1
    // Less    = 0
    //==========================================================

    task reset_comparator;

        begin

            reset             = 1'b1;
            serial_first_bit  = 1'b0;
            serial_second_bit = 1'b0;

            #2;


            // بررسی صحت خروجی‌ها هنگام Reset
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


            // منتظر لبه پایین‌رونده کلاک می‌مانیم.
            @(negedge clock);

            #1;

            // خارج شدن از حالت Reset
            reset = 1'b0;

        end

    endtask


    //==========================================================
    // Task مربوط به مقایسه دو عدد چهار بیتی
    //
    // ورودی‌ها از MSB یعنی بیت 3
    // تا LSB یعنی بیت 0 ارسال می‌شوند.
    //==========================================================

    task compare_words;

        // دو عددی که باید مقایسه شوند
        input [3:0] first_word;
        input [3:0] second_word;

        // شماره بیتی که در حال ارسال است
        integer bit_index;

        // نتیجه صحیح مورد انتظار
        reg expected_greater;
        reg expected_equal;
        reg expected_less;


        begin

            // قبل از شروع، فرض می‌کنیم دو عدد مساوی هستند.
            expected_greater = 1'b0;
            expected_equal   = 1'b1;
            expected_less    = 1'b0;


            // Reset مدار قبل از هر آزمایش
            reset_comparator;


            $display(
                "Testing first=%b second=%b",
                first_word,
                second_word
            );


            // ارسال بیت‌ها از MSB به LSB
            for (
                bit_index = 3;
                bit_index >= 0;
                bit_index = bit_index - 1
            ) begin


                // ورودی‌ها در لبه پایین‌رونده کلاک تغییر می‌کنند.
                @(negedge clock);


                // قرار دادن بیت فعلی روی ورودی سریال
                serial_first_bit =
                    first_word[bit_index];

                serial_second_bit =
                    second_word[bit_index];


                //==================================================
                // محاسبه نتیجه مورد انتظار
                //
                // فقط اگر هنوز دو عدد مساوی باشند،
                // بیت جدید می‌تواند نتیجه را تغییر دهد.
                //==================================================

                if (expected_equal == 1'b1) begin


                    // اگر بیت عدد اول بزرگ‌تر باشد
                    if (
                        first_word[bit_index] >
                        second_word[bit_index]
                    ) begin

                        expected_greater = 1'b1;
                        expected_equal   = 1'b0;
                        expected_less    = 1'b0;

                    end


                    // اگر بیت عدد اول کوچک‌تر باشد
                    else if (
                        first_word[bit_index] <
                        second_word[bit_index]
                    ) begin

                        expected_greater = 1'b0;
                        expected_equal   = 1'b0;
                        expected_less    = 1'b1;

                    end

                end


                // منتظر لبه بالارونده کلاک می‌مانیم.
                @(posedge clock);

                // کمی صبر برای پایدار شدن خروجی
                #1;


                //==================================================
                // مقایسه نتیجه واقعی مدار با نتیجه مورد انتظار
                //==================================================

                if (
                    first_is_greater !== expected_greater ||
                    bits_are_equal   !== expected_equal   ||
                    first_is_less    !== expected_less
                ) begin

                    // ثبت خطا
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

                    // اعلام درست بودن نتیجه این بیت
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


    //==========================================================
    // بخش اصلی اجرای Testbench
    //==========================================================

    initial begin

        // مقادیر اولیه
        reset             = 1'b1;
        serial_first_bit  = 1'b0;
        serial_second_bit = 1'b0;
        error_count       = 0;


        $display("============================================");
        $display("Starting serial comparator simulation");
        $display("============================================");


        //======================================================
        // تست 1: دو عدد مساوی
        // 12 = 12
        //======================================================

        compare_words(
            4'b1100,
            4'b1100
        );


        //======================================================
        // تست 2: عدد اول بزرگ‌تر
        // اختلاف از همان MSB مشخص می‌شود.
        // 8 > 7
        //======================================================

        compare_words(
            4'b1000,
            4'b0111
        );


        //======================================================
        // تست 3: عدد اول کوچک‌تر
        // 4 < 7
        //======================================================

        compare_words(
            4'b0100,
            4'b0111
        );


        //======================================================
        // تست 4: اختلاف در یکی از بیت‌های میانی
        // 11 > 9
        //======================================================

        compare_words(
            4'b1011,
            4'b1001
        );


        //======================================================
        // تست 5: عدد اول کوچک‌تر است.
        // 3 < 4
        //======================================================

        compare_words(
            4'b0011,
            4'b0100
        );


        //======================================================
        // تست 6: اختلاف فقط در LSB
        // 11 > 10
        //======================================================

        compare_words(
            4'b1011,
            4'b1010
        );


        $display("============================================");


        // بررسی نتیجه نهایی تمام آزمایش‌ها
        if (error_count == 0) begin

            $display(
                "ALL SERIAL COMPARATOR TESTS PASSED"
            );

        end
        else begin

            $display(
                "SERIAL SIMULATION FAILED: %0d errors",
                error_count
            );

        end


        $display("============================================");

        // توقف شبیه‌سازی
        $stop;

    end

endmodule
