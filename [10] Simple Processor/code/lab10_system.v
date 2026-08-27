`timescale 1ns/1ps

// cpu + ram + mapped I/O
module lab10_system (
    input             clk,
    input             reset,
    input      [7:0]  input_x,

    output reg [3:0]  digit_low,
    output reg [3:0]  digit_high,
    output reg        led_error,
    output reg        led_done,

    output     [7:0]  debug_pc,
    output     [3:0]  debug_sp,
    output     [7:0]  debug_top,
    output     [7:0]  debug_second,
    output            debug_s,
    output            debug_z,
    output            debug_instr_done
);
    reg [7:0] memory [0:255];

    wire [7:0] cpu_addr;
    wire [7:0] cpu_wdata;
    wire       cpu_we;
    reg  [7:0] cpu_rdata;
    wire       cpu_s;
    wire       cpu_z;
    wire       cpu_instr_done;

    // program is loaded here
    initial begin
`include "lab10_program.vh"
    end

    stack_cpu CPU (
        .clk(clk),
        .reset(reset),
        .mem_addr(cpu_addr),
        .mem_wdata(cpu_wdata),
        .mem_we(cpu_we),
        .mem_rdata(cpu_rdata),
        .flag_s(cpu_s),
        .flag_z(cpu_z),
        .instr_done(cpu_instr_done),
        .debug_pc(debug_pc),
        .debug_sp(debug_sp),
        .debug_top(debug_top),
        .debug_second(debug_second)
    );

    assign debug_s          = cpu_s;
    assign debug_z          = cpu_z;
    assign debug_instr_done = cpu_instr_done;

    // F8 is input port
    always @(*) begin
        if (cpu_addr == 8'hF8)
            cpu_rdata = input_x;
        else if (cpu_addr < 8'hF8)
            cpu_rdata = memory[cpu_addr];
        else
            cpu_rdata = 8'h00;
    end

    // RAM and output ports
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digit_low  <= 4'h0;
            digit_high <= 4'h0;
            led_error  <= 1'b0;
            led_done   <= 1'b0;
        end else if (cpu_we) begin
            case (cpu_addr)
                8'hF9: digit_low  <= cpu_wdata[3:0];
                8'hFA: digit_high <= cpu_wdata[3:0];
                8'hFB: led_error  <= cpu_wdata[0];
                8'hFC: led_done   <= cpu_wdata[0];
                default: begin
                    if (cpu_addr < 8'hF8)
                        memory[cpu_addr] <= cpu_wdata;
                end
            endcase
        end
    end
endmodule
