`timescale 1ns/1ps

// test for the final program
module tb_lab10_program;
    reg clk;
    reg sim_done;
    reg reset;
    reg [7:0] input_x;

    wire [3:0] digit_low;
    wire [3:0] digit_high;
    wire led_error;
    wire led_done;
    wire [7:0] debug_pc;
    wire [3:0] debug_sp;
    wire [7:0] debug_top;
    wire [7:0] debug_second;
    wire debug_s;
    wire debug_z;
    wire debug_instr_done;

    integer errors;
    integer observed_max_sp;

    lab10_system dut (
        .clk(clk),
        .reset(reset),
        .input_x(input_x),
        .digit_low(digit_low),
        .digit_high(digit_high),
        .led_error(led_error),
        .led_done(led_done),
        .debug_pc(debug_pc),
        .debug_sp(debug_sp),
        .debug_top(debug_top),
        .debug_second(debug_second),
        .debug_s(debug_s),
        .debug_z(debug_z),
        .debug_instr_done(debug_instr_done)
    );

    initial begin : clock_gen
        clk = 1'b0;
        forever begin
            #10;
            if (sim_done)
                disable clock_gen;
            clk = ~clk;
        end
    end

    always @(negedge clk) begin
        if (!reset && debug_sp > observed_max_sp)
            observed_max_sp = debug_sp;
    end

    task run_case;
        input [7:0] x_value;
        input exp_error;
        input [7:0] exp_display;
        integer timeout;
        reg [7:0] got_display;
        begin
            input_x = x_value;
            observed_max_sp = 0;
            reset = 1'b1;
            repeat (3) @(negedge clk);
            reset = 1'b0;

            timeout = 0;
            while (led_done !== 1'b1 && timeout < 5000) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            got_display = {digit_high, digit_low};
            if (timeout >= 5000) begin
                $display("x=%0d  timeout  pc=%02h sp=%0d", x_value, debug_pc, debug_sp);
                errors = errors + 1;
            end else if (led_error !== exp_error || got_display !== exp_display) begin
                $display("x=%0d  wrong  out=%02h err=%b  expected=%02h err=%b", 
                         x_value, got_display, led_error, exp_display, exp_error);
                errors = errors + 1;
            end else begin
                $display("x=%0d  out=%02h  err=%b  ok", x_value, got_display, led_error);
            end

            // stack should not go above 2 for this program
            if (observed_max_sp > 2) begin
                $display("x=%0d  stack depth=%0d", x_value, observed_max_sp);
                errors = errors + 1;
            end

            reset = 1'b1;
            repeat (2) @(negedge clk);
        end
    endtask

    initial begin
        sim_done = 1'b0;
        clk = 1'b0;
        reset = 1'b1;
        input_x = 8'h00;
        errors = 0;
        observed_max_sp = 0;

        $display("program test");

        run_case(8'd0,   1'b0, 8'h05);
        run_case(8'd31,  1'b0, 8'h62);
        run_case(8'd32,  1'b0, 8'h54);
        run_case(8'd53,  1'b0, 8'h7E);
        run_case(8'd54,  1'b1, 8'h00);
        run_case(8'd63,  1'b1, 8'h00);
        run_case(8'd64,  1'b0, 8'h18);
        run_case(8'd127, 1'b0, 8'h57);
        run_case(8'd128, 1'b1, 8'h00);
        run_case(8'd255, 1'b1, 8'h00);

        if (errors == 0)
            $display("program test: ok");
        else
            $display("program test: %0d error(s)", errors);
        sim_done = 1'b1;
    end
endmodule
