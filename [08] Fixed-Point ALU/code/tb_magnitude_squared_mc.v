`timescale 1ns/1ps

// Testbench for |z|^2.
// It checks a 3-4-5 style case, another signed case and the zero input.
module tb_magnitude_squared_mc;
    localparam WIDTH=8;
    localparam RW=2*WIDTH+1;

    reg clk,reset,start;
    reg signed [WIDTH-1:0] ar,ai;
    wire signed [RW-1:0] result;
    wire valid,busy;
    integer errors;
    integer test_no;

    magnitude_squared_mc #(.WIDTH(WIDTH),.RESULT_WIDTH(RW)) dut(
        .clk(clk),.reset(reset),.start(start),
        .a_real(ar),.a_imag(ai),
        .result(result),.valid(valid),.busy(busy)
    );

    always #5 clk=~clk;

    // Apply one complex input and compare the real magnitude-squared result after valid.
    task run_case;
        input integer iar,iai,expected;
        begin
            test_no=test_no+1;

            @(negedge clk);
            ar=iar; ai=iai; start=1'b1;
            @(negedge clk);
            start=1'b0;

            wait(valid==1'b1);
            #1;

            $display("------------------------------------------------------------");
            $display("TEST %0d : MAGNITUDE SQUARED",test_no);
            $display("input    = (%0d,%0d)",iar,iai);
            $display("expected = %0d",expected);
            $display("got      = %0d",$signed(result));

            if($signed(result)!==expected) begin
                $display("RESULT   : FAIL");
                errors=errors+1;
            end else begin
                $display("RESULT   : PASS");
            end

            @(negedge clk);
        end
    endtask

    // Reset first, then run the three magnitude cases.
    initial begin
        clk=0;reset=1;start=0;ar=0;ai=0;
        errors=0;test_no=0;

        $display("============================================================");
        $display("     Lab 8 - Magnitude Squared Testbench");
        $display("============================================================");

        repeat(2) @(negedge clk);
        reset=0;

        run_case(3,-4,25);
        run_case(-10,5,125);
        run_case(0,0,0);

        $display("============================================================");
        if(errors==0)
            $display("MAG2 SUMMARY : ALL 3 TESTS PASSED");
        else
            $display("MAG2 SUMMARY : %0d TEST(S) FAILED",errors);
        $display("============================================================");
        $finish;
    end
endmodule
