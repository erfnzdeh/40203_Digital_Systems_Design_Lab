`timescale 1ns/1ps

// separate test for swap, shl and cmp
module tb_new_instructions;
    reg clk;
    reg sim_done;
    reg reset;

    wire [7:0] mem_addr;
    wire [7:0] mem_wdata;
    wire mem_we;
    reg  [7:0] mem_rdata;
    wire flag_s;
    wire flag_z;
    wire instr_done;
    wire [7:0] debug_pc;
    wire [3:0] debug_sp;
    wire [7:0] debug_top;
    wire [7:0] debug_second;

    reg [7:0] mem [0:255];
    integer errors;

    stack_cpu dut (
        .clk(clk),
        .reset(reset),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_we(mem_we),
        .mem_rdata(mem_rdata),
        .flag_s(flag_s),
        .flag_z(flag_z),
        .instr_done(instr_done),
        .debug_pc(debug_pc),
        .debug_sp(debug_sp),
        .debug_top(debug_top),
        .debug_second(debug_second)
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

    always @(*) begin
        mem_rdata = mem[mem_addr];
    end

    always @(posedge clk) begin
        if (mem_we)
            mem[mem_addr] <= mem_wdata;
    end

    task clear_memory;
        integer k;
        begin
            for (k = 0; k < 256; k = k + 1)
                mem[k] = 8'hB0; // reserved opcode
        end
    endtask

    task begin_test;
        begin
            reset = 1'b1;
            repeat (2) @(negedge clk);
            reset = 1'b0;
        end
    endtask

    task wait_instructions;
        input integer count;
        integer n;
        begin
            for (n = 0; n < count; n = n + 1)
                @(posedge instr_done);
            #1;
        end
    endtask

    task test_swap;
        begin
            clear_memory;
            // make S=1 first, then check swap and flags
            mem[8'h00] = 8'h00; mem[8'h01] = 8'h01; // pushc 1
            mem[8'h02] = 8'h00; mem[8'h03] = 8'h02; // pushc 2
            mem[8'h04] = 8'h70;                     // sub
            mem[8'h05] = 8'h20; mem[8'h06] = 8'hD0; // pop
            mem[8'h07] = 8'h00; mem[8'h08] = 8'h12; // pushc 12
            mem[8'h09] = 8'h00; mem[8'h0A] = 8'h34; // pushc 34
            mem[8'h0B] = 8'h80;                     // swap

            begin_test;
            wait_instructions(7);

            if (debug_sp !== 4'd2 || debug_top !== 8'h12 || debug_second !== 8'h34 ||
                flag_s !== 1'b1 || flag_z !== 1'b0) begin
                $display("swap: error  sp=%0d top=%02h second=%02h s=%b z=%b",
                         debug_sp, debug_top, debug_second, flag_s, flag_z);
                errors = errors + 1;
            end else begin
                $display("swap: ok");
            end
            reset = 1'b1;
            @(negedge clk);
        end
    endtask

    task test_shl_value;
        input [7:0] value;
        input [7:0] expected;
        begin
            clear_memory;
            // SHL must not change S and Z
            mem[8'h00] = 8'h00; mem[8'h01] = 8'h01;
            mem[8'h02] = 8'h00; mem[8'h03] = 8'h02;
            mem[8'h04] = 8'h70;
            mem[8'h05] = 8'h20; mem[8'h06] = 8'hD0;
            mem[8'h07] = 8'h00; mem[8'h08] = value;
            mem[8'h09] = 8'h90;

            begin_test;
            wait_instructions(6);

            if (debug_sp !== 4'd1 || debug_top !== expected ||
                flag_s !== 1'b1 || flag_z !== 1'b0) begin
                $display("shl %0d: error  got=%0d expected=%0d s=%b z=%b",
                         value, debug_top, expected, flag_s, flag_z);
                errors = errors + 1;
            end else begin
                $display("shl %0d -> %0d  ok", value, debug_top);
            end
            reset = 1'b1;
            @(negedge clk);
        end
    endtask

    task test_cmp_case;
        input [7:0] b_value;
        input [7:0] a_value;
        input exp_s;
        input exp_z;
        begin
            clear_memory;
            // B is pushed before A
            mem[8'h00] = 8'h00; mem[8'h01] = b_value;
            mem[8'h02] = 8'h00; mem[8'h03] = a_value;
            mem[8'h04] = 8'hA0;

            begin_test;
            wait_instructions(3);

            if (debug_sp !== 4'd2 || debug_top !== a_value || debug_second !== b_value ||
                flag_s !== exp_s || flag_z !== exp_z) begin
                $display("cmp b=%0d a=%0d: error  s=%b z=%b", b_value, a_value, flag_s, flag_z);
                errors = errors + 1;
            end else begin
                $display("cmp b=%0d a=%0d: s=%b z=%b  ok", b_value, a_value, flag_s, flag_z);
            end
            reset = 1'b1;
            @(negedge clk);
        end
    endtask

    initial begin
        sim_done = 1'b0;
        clk = 1'b0;
        reset = 1'b1;
        mem_rdata = 8'h00;
        errors = 0;
        clear_memory;

        $display("new instructions test");

        test_swap;
        test_shl_value(8'd0,   8'd0);
        test_shl_value(8'd1,   8'd2);
        test_shl_value(8'd63,  8'd126);
        test_shl_value(8'd127, 8'd254);

        test_cmp_case(8'd5, 8'd7, 1'b1, 1'b0);
        test_cmp_case(8'd5, 8'd5, 1'b0, 1'b1);
        test_cmp_case(8'd7, 8'd5, 1'b0, 1'b0);

        if (errors == 0)
            $display("new instructions test: ok");
        else
            $display("new instructions test: %0d error(s)", errors);
        sim_done = 1'b1;
    end
endmodule
