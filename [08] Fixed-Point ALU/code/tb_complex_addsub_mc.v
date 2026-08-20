`timescale 1ns/1ps


// Testbench for complex add/sub.
// Each case sends a one-clock start pulse, waits for valid, then compares result and overflow.
module tb_complex_addsub_mc;
    localparam WIDTH = 8;
    localparam RW = 2*WIDTH+1;

    reg clk, reset, start, sub;
    reg signed [WIDTH-1:0] ar, ai, br, bi;
    wire signed [RW-1:0] rr, ri;
    wire valid, overflow, busy;
    integer errors;
    integer test_no;

    complex_addsub_mc #(.WIDTH(WIDTH), .RESULT_WIDTH(RW)) dut (
        .clk(clk), .reset(reset), .start(start), .sub(sub),
        .a_real(ar), .a_imag(ai), .b_real(br), .b_imag(bi),
        .result_real(rr), .result_imag(ri),
        .valid(valid), .overflow(overflow), .busy(busy)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    // I put the repeated stimulus/check code in a task so adding test cases is easier.
    task run_case;
        input op;
        input integer iar, iai, ibr, ibi;
        input integer exp_r, exp_i;
        input exp_ovf;
        begin
            test_no = test_no + 1;

            @(negedge clk);
            ar = iar; ai = iai;
            br = ibr; bi = ibi;
            sub = op;
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // output is checked only when the module says it is valid
            wait(valid == 1'b1);
            #1;

            $display("------------------------------------------------------------");
            if (op == 1'b0)
                $display("TEST %0d : COMPLEX ADD", test_no);
            else
                $display("TEST %0d : COMPLEX SUB", test_no);
            $display("A = (%0d,%0d)   B = (%0d,%0d)", iar, iai, ibr, ibi);
            $display("expected = (%0d,%0d), overflow=%b", exp_r, exp_i, exp_ovf);
            $display("got      = (%0d,%0d), overflow=%b", $signed(rr), $signed(ri), overflow);

            if (($signed(rr) !== exp_r) || ($signed(ri) !== exp_i) || (overflow !== exp_ovf)) begin
                $display("RESULT   : FAIL");
                errors = errors + 1;
            end else begin
                $display("RESULT   : PASS");
            end

            @(negedge clk);
        end
    endtask

    // Reset once at the beginning, then run normal, negative and overflow cases.
    initial begin
        clk=0; reset=1; start=0; sub=0;
        ar=0; ai=0; br=0; bi=0;
        errors=0; test_no=0;

        $display("============================================================");
        $display("     Lab 8 - Complex Add/Sub Testbench");
        $display("============================================================");

        repeat(2) @(negedge clk);
        reset=0;

        // positive + positive
        run_case(0, 3, 4, 5, 2, 8, 6, 0);

        // negative + negative
        run_case(0, -3, -4, -5, -2, -8, -6, 0);

        // subtraction with negative result
        run_case(1, 2, 3, 7, 8, -5, -5, 0);

        // 127 + 1 does not fit in signed 8 bit, so overflow must be 1
        run_case(0, 127, 0, 1, 0, 128, 0, 1);

        $display("============================================================");
        if (errors == 0)
            $display("ADD/SUB SUMMARY : ALL 4 TESTS PASSED");
        else
            $display("ADD/SUB SUMMARY : %0d TEST(S) FAILED", errors);
        $display("============================================================");
        $finish;
    end
endmodule
