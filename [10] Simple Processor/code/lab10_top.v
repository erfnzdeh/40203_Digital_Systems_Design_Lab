`timescale 1ns/1ps

// top module for FPGA
module lab10_top (
    input             clk,
    input             reset_n,
    input      [7:0]  switches,
    output     [6:0]  hex0,
    output     [6:0]  hex1,
    output            led_error,
    output            led_done
);
    wire [3:0] digit_low;
    wire [3:0] digit_high;
    wire [7:0] unused_pc;
    wire [3:0] unused_sp;
    wire [7:0] unused_top;
    wire [7:0] unused_second;
    wire unused_s;
    wire unused_z;
    wire unused_instr_done;

    lab10_system SYS (
        .clk(clk),
        .reset(~reset_n),
        .input_x(switches),
        .digit_low(digit_low),
        .digit_high(digit_high),
        .led_error(led_error),
        .led_done(led_done),
        .debug_pc(unused_pc),
        .debug_sp(unused_sp),
        .debug_top(unused_top),
        .debug_second(unused_second),
        .debug_s(unused_s),
        .debug_z(unused_z),
        .debug_instr_done(unused_instr_done)
    );

    sevenseg_hex #(.ACTIVE_LOW(1)) HEX_LOW (
        .hex(digit_low),
        .seg(hex0)
    );

    sevenseg_hex #(.ACTIVE_LOW(1)) HEX_HIGH (
        .hex(digit_high),
        .seg(hex1)
    );
endmodule
