`timescale 1ns/1ps


// Final testbench for the whole processor.
// The instruction memory contains eight operations, and every valid result is checked using its PC.
module tb_complex_processor;
    localparam WIDTH=8;
    localparam RW=2*WIDTH+1;

    reg clk,reset,start;
    wire signed [RW-1:0] rr,ri;
    wire valid,overflow,zero,real_negative,imag_negative,busy,done;
    wire [4:0] result_pc;
    integer errors, seen;

    complex_processor #(.WIDTH(WIDTH),.RESULT_WIDTH(RW),.PROGRAM_LENGTH(8)) dut(
        .clk(clk),.reset(reset),.start(start),
        .result_real(rr),.result_imag(ri),
        .valid(valid),.overflow(overflow),.zero(zero),
        .real_negative(real_negative),.imag_negative(imag_negative),
        .result_pc(result_pc),.busy(busy),.done(done)
    );

    always #5 clk=~clk;

    // This task compares the complex result and all four status flags for one completed instruction.
    task check_result;
        input [4:0] pc;
        input integer exp_r,exp_i;
        input exp_ovf,exp_zero,exp_nr,exp_ni;
        begin
            $display("------------------------------------------------------------");
            $display("Instruction PC=%0d completed",pc);
            $display("expected = (%0d,%0d) flags O/Z/NR/NI=%b%b%b%b",
                     exp_r,exp_i,exp_ovf,exp_zero,exp_nr,exp_ni);
            $display("got      = (%0d,%0d) flags O/Z/NR/NI=%b%b%b%b",
                     $signed(rr),$signed(ri),overflow,zero,real_negative,imag_negative);

            if(($signed(rr)!==exp_r)||($signed(ri)!==exp_i)||
               (overflow!==exp_ovf)||(zero!==exp_zero)||
               (real_negative!==exp_nr)||(imag_negative!==exp_ni)) begin
                $display("RESULT   : FAIL");
                errors=errors+1;
            end else begin
                $display("RESULT   : PASS");
            end
            seen=seen+1;
        end
    endtask

    // Sample on the falling edge so values assigned at the previous rising edge are already stable.
    always @(negedge clk) begin
        if(valid) begin
            case(result_pc)
                0: check_result(result_pc,  8,  6, 0,0,0,0); // CADD
                1: check_result(result_pc, -8, -6, 0,0,1,1); // CADD negative
                2: check_result(result_pc, -5, -5, 0,0,1,1); // CSUB
                3: check_result(result_pc,-23, -2, 0,0,1,1); // CMUL
                4: check_result(result_pc, -6, -7, 0,0,1,1); // CONJ
                5: check_result(result_pc, 25,  0, 0,0,0,0); // MAG2
                6: check_result(result_pc,  0,  0, 0,1,0,0); // zero flag
                7: check_result(result_pc,128,  0, 1,0,0,0); // overflow flag
                default: begin
                    $display("FAIL : unexpected result_pc=%0d",result_pc);
                    errors=errors+1;
                end
            endcase
        end
    end

    // Start the processor once and wait until the complete memory program has finished.
    initial begin
        clk=0;reset=1;start=0;
        errors=0;seen=0;

        $display("============================================================");
        $display("      Lab 8 - Complete Processor Testbench");
        $display("============================================================");
        $display("The memory contains 8 test instructions.");

        // reset first, then one clock start pulse
        repeat(3) @(negedge clk);
        reset=0;
        @(negedge clk); start=1;
        @(negedge clk); start=0;

        wait(done==1'b1);
        repeat(2) @(negedge clk);

        if(seen!=8) begin
            $display("FAIL : expected 8 completed instructions, saw %0d",seen);
            errors=errors+1;
        end

        $display("============================================================");
        if(errors==0)
            $display("FINAL RESULT : ALL 8 PROCESSOR TESTS PASSED");
        else
            $display("FINAL RESULT : PROCESSOR HAS %0d ERROR(S)",errors);
        $display("============================================================");
        $finish;
    end
endmodule
