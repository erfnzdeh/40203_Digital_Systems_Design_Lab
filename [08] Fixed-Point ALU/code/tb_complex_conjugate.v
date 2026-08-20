`timescale 1ns/1ps

// Testbench for conjugate operation.
// I test both positive and negative imaginary inputs to make sure the sign is flipped correctly.
module tb_complex_conjugate;
    localparam WIDTH=8;
    localparam RW=2*WIDTH+1;

    reg clk,reset,start;
    reg signed [WIDTH-1:0] ar,ai;
    wire signed [RW-1:0] rr,ri;
    wire valid,busy;
    integer errors;
    integer test_no;

    complex_conjugate #(.WIDTH(WIDTH),.RESULT_WIDTH(RW)) dut(
        .clk(clk),.reset(reset),.start(start),
        .a_real(ar),.a_imag(ai),
        .result_real(rr),.result_imag(ri),.valid(valid),.busy(busy)
    );

    always #5 clk=~clk;

    // Apply one complex input, wait for valid and compare both output components.
    task run_case;
        input integer iar,iai,exp_r,exp_i;
        begin
            test_no=test_no+1;

            @(negedge clk);
            ar=iar; ai=iai; start=1'b1;
            @(negedge clk);
            start=1'b0;

            wait(valid==1'b1);
            #1;

            $display("------------------------------------------------------------");
            $display("TEST %0d : CONJUGATE",test_no);
            $display("input    = (%0d,%0d)",iar,iai);
            $display("expected = (%0d,%0d)",exp_r,exp_i);
            $display("got      = (%0d,%0d)",$signed(rr),$signed(ri));

            if(($signed(rr)!==exp_r)||($signed(ri)!==exp_i)) begin
                $display("RESULT   : FAIL");
                errors=errors+1;
            end else begin
                $display("RESULT   : PASS");
            end

            @(negedge clk);
        end
    endtask

    // Basic reset followed by two sign cases.
    initial begin
        clk=0;reset=1;start=0;ar=0;ai=0;
        errors=0;test_no=0;

        $display("============================================================");
        $display("     Lab 8 - Complex Conjugate Testbench");
        $display("============================================================");

        repeat(2) @(negedge clk);
        reset=0;

        run_case(-6,7,-6,-7);
        run_case(4,-9,4,9);

        $display("============================================================");
        if(errors==0)
            $display("CONJUGATE SUMMARY : ALL 2 TESTS PASSED");
        else
            $display("CONJUGATE SUMMARY : %0d TEST(S) FAILED",errors);
        $display("============================================================");
        $finish;
    end
endmodule
