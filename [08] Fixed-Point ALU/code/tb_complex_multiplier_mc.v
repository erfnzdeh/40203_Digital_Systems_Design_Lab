`timescale 1ns/1ps

// Testbench for the multi-cycle complex multiplier.
// The cases include mixed signs and a simple imaginary-only multiplication.
module tb_complex_multiplier_mc;
    localparam WIDTH = 8;
    localparam RW = 2*WIDTH+1;

    reg clk, reset, start;
    reg signed [WIDTH-1:0] ar, ai, br, bi;
    wire signed [RW-1:0] rr, ri;
    wire valid, busy;
    integer errors;
    integer test_no;

    complex_multiplier_mc #(.WIDTH(WIDTH), .RESULT_WIDTH(RW)) dut (
        .clk(clk), .reset(reset), .start(start),
        .a_real(ar), .a_imag(ai), .b_real(br), .b_imag(bi),
        .result_real(rr), .result_imag(ri), .valid(valid), .busy(busy)
    );

    always #5 clk = ~clk;

    // Since the multiplier is multi-cycle, the task always waits for valid before checking.
    task run_case;
        input integer iar, iai, ibr, ibi;
        input integer exp_r, exp_i;
        begin
            test_no = test_no + 1;

            @(negedge clk);
            ar=iar; ai=iai; br=ibr; bi=ibi;
            start=1'b1;
            @(negedge clk);
            start=1'b0;

            // multiplication takes several clocks, so I wait for valid
            wait(valid == 1'b1);
            #1;

            $display("------------------------------------------------------------");
            $display("TEST %0d : COMPLEX MULTIPLICATION", test_no);
            $display("A = (%0d,%0d)   B = (%0d,%0d)", iar, iai, ibr, ibi);
            $display("expected = (%0d,%0d)", exp_r, exp_i);
            $display("got      = (%0d,%0d)", $signed(rr), $signed(ri));

            if (($signed(rr) !== exp_r) || ($signed(ri) !== exp_i)) begin
                $display("RESULT   : FAIL");
                errors=errors+1;
            end else begin
                $display("RESULT   : PASS");
            end

            @(negedge clk);
        end
    endtask

    // Reset first, then run three representative multiplication cases.
    initial begin
        clk=0; reset=1; start=0;
        ar=0; ai=0; br=0; bi=0;
        errors=0; test_no=0;

        $display("============================================================");
        $display("     Lab 8 - Complex Multiplier Testbench");
        $display("============================================================");

        repeat(2) @(negedge clk);
        reset=0;

        // mixed positive and negative components
        run_case(2, 3, -4, 5, -23, -2);
        run_case(-10, 5, 3, -8, 10, 95);
        run_case(0, 2, 0, 2, -4, 0);

        $display("============================================================");
        if(errors==0)
            $display("MULTIPLIER SUMMARY : ALL 3 TESTS PASSED");
        else
            $display("MULTIPLIER SUMMARY : %0d TEST(S) FAILED", errors);
        $display("============================================================");
        $finish;
    end
endmodule
