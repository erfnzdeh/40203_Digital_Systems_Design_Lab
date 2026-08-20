`timescale 1ns/1ps

// Testbench for the complete complex ALU.
// This checks all opcodes plus zero, negative and overflow status flags.
module tb_complex_alu_mc;
    localparam WIDTH=8;
    localparam RW=2*WIDTH+1;

    reg clk,reset,start;
    reg [2:0] opcode;
    reg signed [WIDTH-1:0] ar,ai,br,bi;
    wire signed [RW-1:0] rr,ri;
    wire valid,overflow,zero,real_negative,imag_negative,busy;
    integer errors;
    integer test_no;

    complex_alu_mc #(.WIDTH(WIDTH),.RESULT_WIDTH(RW)) dut(
        .clk(clk),.reset(reset),.start(start),.opcode(opcode),
        .a_real(ar),.a_imag(ai),.b_real(br),.b_imag(bi),
        .result_real(rr),.result_imag(ri),
        .valid(valid),.overflow(overflow),.zero(zero),
        .real_negative(real_negative),.imag_negative(imag_negative),.busy(busy)
    );

    always #5 clk=~clk;

    // One common task is used for both single-cycle-looking and multi-cycle ALU operations.
    task run_case;
        input [2:0] op;
        input integer iar,iai,ibr,ibi,exp_r,exp_i;
        input exp_ovf,exp_zero,exp_nr,exp_ni;
        begin
            test_no=test_no+1;

            @(negedge clk);
            opcode=op;
            ar=iar; ai=iai; br=ibr; bi=ibi;
            start=1'b1;
            @(negedge clk);
            start=1'b0;

            // CMUL and MAG2 need more clocks, valid tells me when to check
            wait(valid==1'b1);
            #1;

            $display("------------------------------------------------------------");
            $display("TEST %0d : ALU opcode=%b",test_no,op);
            $display("A=(%0d,%0d)  B=(%0d,%0d)",iar,iai,ibr,ibi);
            $display("expected result=(%0d,%0d) flags O/Z/NR/NI=%b%b%b%b",
                     exp_r,exp_i,exp_ovf,exp_zero,exp_nr,exp_ni);
            $display("got      result=(%0d,%0d) flags O/Z/NR/NI=%b%b%b%b",
                     $signed(rr),$signed(ri),overflow,zero,real_negative,imag_negative);

            if(($signed(rr)!==exp_r)||($signed(ri)!==exp_i)||
               (overflow!==exp_ovf)||(zero!==exp_zero)||
               (real_negative!==exp_nr)||(imag_negative!==exp_ni)) begin
                $display("RESULT   : FAIL");
                errors=errors+1;
            end else begin
                $display("RESULT   : PASS");
            end

            @(negedge clk);
        end
    endtask

    // The selected cases match the main situations required in the lab sheet.
    initial begin
        clk=0;reset=1;start=0;opcode=0;
        ar=0;ai=0;br=0;bi=0;
        errors=0;test_no=0;

        $display("============================================================");
        $display("        Lab 8 - Final Complex ALU Testbench");
        $display("============================================================");
        $display("opcode: 000=CADD 001=CSUB 010=CMUL 011=CONJ 100=MAG2");

        repeat(2) @(negedge clk);
        reset=0;

        // 1) positive addition
        run_case(3'b000,3,4,5,2,8,6,0,0,0,0);

        // 2) negative addition -> negative flags
        run_case(3'b000,-3,-4,-5,-2,-8,-6,0,0,1,1);

        // 3) subtraction with negative result
        run_case(3'b001,2,3,7,8,-5,-5,0,0,1,1);

        // 4) multi-cycle complex multiplication
        run_case(3'b010,2,3,-4,5,-23,-2,0,0,1,1);

        // 5) conjugate
        run_case(3'b011,-6,7,0,0,-6,-7,0,0,1,1);

        // 6) magnitude squared: 3^2 + (-4)^2 = 25
        run_case(3'b100,3,-4,0,0,25,0,0,0,0,0);

        // 7) zero flag
        run_case(3'b000,5,-5,-5,5,0,0,0,1,0,0);

        // 8) signed 8-bit overflow case
        run_case(3'b000,127,0,1,0,128,0,1,0,0,0);

        $display("============================================================");
        if(errors==0)
            $display("ALU SUMMARY : ALL 8 TESTS PASSED");
        else
            $display("ALU SUMMARY : %0d TEST(S) FAILED",errors);
        $display("============================================================");
        $finish;
    end
endmodule
