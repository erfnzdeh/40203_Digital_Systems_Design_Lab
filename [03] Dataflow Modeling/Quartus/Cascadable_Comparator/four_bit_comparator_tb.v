`timescale 1ns/1ps

module four_bit_comparator_tb;

    // ورودی‌های آزمایشی مدار
    reg [3:0] test_first_number;
    reg [3:0] test_second_number;

    // خروجی‌های مدار تحت آزمایش
    wire result_greater;
    wire result_equal;
    wire result_less;

    // متغیرهای حلقه برای تولید تمام ورودی‌ها
    integer first_value;
    integer second_value;

    // تعداد خطاهای پیدا شده در شبیه‌سازی
    integer error_count;


    // نمونه‌سازی مدار اصلی برای انجام آزمایش
    four_bit_comparator dut (

        .first_number      (test_first_number),
        .second_number     (test_second_number),

        .first_is_greater  (result_greater),
        .numbers_are_equal (result_equal),
        .first_is_less     (result_less)
    );


    initial begin

        // مقدار اولیه ورودی‌ها و شمارنده خطا
        test_first_number  = 4'b0000;
        test_second_number = 4'b0000;
        error_count        = 0;

        $display("--------------------------------------------");
        $display("Starting exhaustive comparator simulation");
        $display("--------------------------------------------");


        // عدد اول از 0 تا 15 تغییر می‌کند.
        for (
            first_value = 0;
            first_value < 16;
            first_value = first_value + 1
        ) begin

            // برای هر عدد اول، عدد دوم نیز از 0 تا 15 تغییر می‌کند.
            for (
                second_value = 0;
                second_value < 16;
                second_value = second_value + 1
            ) begin

                // اعمال ورودی‌ها به مدار
                test_first_number  = first_value;
                test_second_number = second_value;

                // زمان لازم برای پایدار شدن خروجی مدار ترکیبی
                #10;


                // مقایسه خروجی مدار با نتیجه صحیح Verilog
                if (
                    (result_greater !==
                        (test_first_number > test_second_number)) ||

                    (result_equal !==
                        (test_first_number == test_second_number)) ||

                    (result_less !==
                        (test_first_number < test_second_number))
                ) begin

                    // اگر پاسخ اشتباه باشد، یک خطا ثبت می‌شود.
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


        // اعلام نتیجه نهایی شبیه‌سازی
        if (error_count == 0) begin

            $display("--------------------------------------------");
            $display("ALL 256 TEST CASES PASSED SUCCESSFULLY");
            $display("--------------------------------------------");

        end
        else begin

            $display("--------------------------------------------");
            $display(
                "SIMULATION FAILED: %d errors detected",
                error_count
            );
            $display("--------------------------------------------");

        end

        // توقف شبیه‌سازی
        $stop;

    end

endmodule
