`timescale 1ns/1ps

module Tester;

    parameter integer TICKS_BIT = 2;

    reg        clk;
    reg        rstN;
    reg        new_data;
    reg  [6:0] send_data;

    wire       tx;
    wire       busy;
    wire [6:0] rec_data;
    wire       rec_new_data;
    wire       correct_data;

    // Independent RX path used to inject parity and stop-bit errors.
    reg        fault_rx;
    wire [6:0] fault_data;
    wire       fault_new_data;
    wire       fault_correct;

    integer errors;

    UARTTop #(
        .TICKS_BIT(TICKS_BIT)
    ) dut (
        .clk          (clk),
        .rstN         (rstN),
        .new_data     (new_data),
        .send_data    (send_data),
        .tx           (tx),
        .busy         (busy),
        .rec_data     (rec_data),
        .rec_new_data (rec_new_data),
        .correct_data (correct_data)
    );

    UARTReceiver #(
        .TICKS_BIT(TICKS_BIT)
    ) fault_receiver (
        .clk          (clk),
        .rstN         (rstN),
        .rx           (fault_rx),
        .data_rec     (fault_data),
        .data_new_rec (fault_new_data),
        .data_correct (fault_correct)
    );

    // 10 ns clock period.
    always #5 clk = ~clk;

    task reset_all;
        begin
            rstN      = 1'b0;
            new_data  = 1'b0;
            send_data = 7'd0;
            fault_rx  = 1'b1;
            repeat (4) @(posedge clk);
            @(negedge clk);
            rstN = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task send_valid_word;
        input [6:0] value;
        begin
            wait (busy == 1'b0);
            @(negedge clk);
            send_data = value;
            new_data  = 1'b1;
            @(negedge clk);
            new_data  = 1'b0;
        end
    endtask

    // Hold each manually driven serial bit for TICKS_BIT clock cycles.
    task drive_fault_bit;
        input bit_value;
        begin
            @(negedge clk);
            fault_rx = bit_value;
            repeat (TICKS_BIT) @(posedge clk);
        end
    endtask

    // Generate a frame with optional parity or stop-bit corruption.
    task send_manual_frame;
        input [6:0] value;
        input       parity_error;
        input       stop_error;
        integer i;
        reg p;
        begin
            p = (^value) ^ parity_error;

            drive_fault_bit(1'b1);
            drive_fault_bit(1'b0);
            drive_fault_bit(p);

            for (i = 0; i < 7; i = i + 1)
                drive_fault_bit(value[i]);

            drive_fault_bit(stop_error ? 1'b0 : 1'b1);
            drive_fault_bit(1'b1);
        end
    endtask

    initial begin
        clk    = 1'b0;
        errors = 0;
        reset_all;

        $display("==============================================");
        $display("UART Lab 7 simulation started");
        $display("TICKS_BIT = %0d", TICKS_BIT);
        $display("==============================================");

        // Test 1: valid frame.
        $display("\nTEST 1 - correct frame: 7'b1011001");
        send_valid_word(7'b1011001);
        @(posedge rec_new_data);
        #1;
        if ((rec_data == 7'b1011001) && (correct_data == 1'b1))
            $display("PASS: rec_data=%b correct_data=%b", rec_data, correct_data);
        else begin
            $display("FAIL: rec_data=%b correct_data=%b", rec_data, correct_data);
            errors = errors + 1;
        end

        // Test 2: corrupted parity bit.
        $display("\nTEST 2 - intentional parity error");
        fork
            send_manual_frame(7'b1011001, 1'b1, 1'b0);
            begin
                @(posedge fault_new_data);
                #1;
                if (fault_correct == 1'b0)
                    $display("PASS: parity error detected, correct_data=0");
                else begin
                    $display("FAIL: parity error was not detected");
                    errors = errors + 1;
                end
            end
        join

        // Test 3: stop bit forced to zero.
        $display("\nTEST 3 - intentional stop-bit error");
        fork
            send_manual_frame(7'b1011001, 1'b0, 1'b1);
            begin
                @(posedge fault_new_data);
                #1;
                if (fault_correct == 1'b0)
                    $display("PASS: stop-bit error detected, correct_data=0");
                else begin
                    $display("FAIL: stop-bit error was not detected");
                    errors = errors + 1;
                end
            end
        join

        reset_all;

        // Test 4: two valid frames sent sequentially.
        $display("\nTEST 4 - two sequential frames");

        send_valid_word(7'b1011001);
        @(posedge rec_new_data);
        #1;
        if ((rec_data == 7'b1011001) && (correct_data == 1'b1))
            $display("PASS frame A: %b", rec_data);
        else begin
            $display("FAIL frame A: rec_data=%b correct=%b", rec_data, correct_data);
            errors = errors + 1;
        end

        send_valid_word(7'b0101101);
        @(posedge rec_new_data);
        #1;
        if ((rec_data == 7'b0101101) && (correct_data == 1'b1))
            $display("PASS frame B: %b", rec_data);
        else begin
            $display("FAIL frame B: rec_data=%b correct=%b", rec_data, correct_data);
            errors = errors + 1;
        end

        // Test 5: data_new during busy must be ignored.
        $display("\nTEST 5 - data_new asserted while busy");

        send_valid_word(7'b1100101);
        wait (busy == 1'b1);
        repeat (3) @(posedge clk);

        @(negedge clk);
        if (busy !== 1'b1) begin
            $display("FAIL: transmitter was expected to be busy");
            errors = errors + 1;
        end

        send_data = 7'b0011110;
        new_data  = 1'b1;
        @(negedge clk);
        new_data  = 1'b0;

        // The active frame must retain the data latched before busy was asserted.
        @(posedge rec_new_data);
        #1;
        if ((rec_data == 7'b1100101) && (correct_data == 1'b1))
            $display("PASS: active frame was not corrupted; rec_data=%b", rec_data);
        else begin
            $display("FAIL: busy-time data_new corrupted active frame: rec_data=%b correct=%b",
                     rec_data, correct_data);
            errors = errors + 1;
        end

        // Verify that the ignored request does not create an extra frame.
        wait (busy == 1'b0);
        repeat (10*TICKS_BIT + 5) begin
            @(posedge clk);
            #1;
            if (rec_new_data === 1'b1) begin
                $display("FAIL: a second frame was generated from data_new asserted during busy");
                errors = errors + 1;
            end
        end

        if (rec_data == 7'b1100101)
            $display("PASS: busy-time request was ignored; no extra frame was received");

        $display("\n==============================================");
        if (errors == 0)
            $display("ALL REQUIRED + EXTRA TESTS PASSED");
        else
            $display("SIMULATION FINISHED WITH %0d ERROR(S)", errors);
        $display("==============================================");

        #20;
        $finish;
    end

    initial begin
        $monitor("time=%0t rstN=%b new_data=%b send_data=%b tx=%b busy=%b rec_data=%b rec_new=%b correct=%b",
                 $time, rstN, new_data, send_data, tx, busy, rec_data, rec_new_data, correct_data);
    end

endmodule
