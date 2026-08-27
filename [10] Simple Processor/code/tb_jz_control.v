`timescale 1ns/1ps

// quick test for JZ
module tb_jz_control;
    reg clk, reset;
    reg sim_done;
    wire [7:0] mem_addr, mem_wdata;
    wire mem_we;
    reg [7:0] mem_rdata;
    wire s, z, instr_done;
    wire [7:0] pc, top, second;
    wire [3:0] sp;
    reg [7:0] mem [0:255];
    integer i;
    integer errors;
    integer timeout;

    stack_cpu dut(
        .clk(clk), .reset(reset),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_we(mem_we), .mem_rdata(mem_rdata),
        .flag_s(s), .flag_z(z), .instr_done(instr_done),
        .debug_pc(pc), .debug_sp(sp), .debug_top(top), .debug_second(second)
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
    always @(*) mem_rdata = mem[mem_addr];
    always @(posedge clk) if(mem_we) mem[mem_addr] <= mem_wdata;

    initial begin
        sim_done = 1'b0;
        clk=0; reset=1; errors=0; timeout=0;
        for(i=0;i<256;i=i+1) mem[i]=8'hB0;
        mem[8'hD0]=8'h00;

        // CMP makes Z=1, so JZ should go to 20h
        mem[8'h00]=8'h00; mem[8'h01]=8'h05;
        mem[8'h02]=8'h00; mem[8'h03]=8'h05;
        mem[8'h04]=8'hA0;
        mem[8'h05]=8'h20; mem[8'h06]=8'hD1;
        mem[8'h07]=8'h20; mem[8'h08]=8'hD1;
        mem[8'h09]=8'h00; mem[8'h0A]=8'h20;
        mem[8'h0B]=8'h40;

        // if jump is not taken
        mem[8'h0C]=8'h00; mem[8'h0D]=8'h55;
        mem[8'h0E]=8'h20; mem[8'h0F]=8'hD0;
        mem[8'h10]=8'h00; mem[8'h11]=8'h18;
        mem[8'h12]=8'h30;
        mem[8'h18]=8'h00; mem[8'h19]=8'h18;
        mem[8'h1A]=8'h30;

        // correct jump path
        mem[8'h20]=8'h00; mem[8'h21]=8'hAA;
        mem[8'h22]=8'h20; mem[8'h23]=8'hD0;
        mem[8'h24]=8'h00; mem[8'h25]=8'h2C;
        mem[8'h26]=8'h30;
        mem[8'h2C]=8'h00; mem[8'h2D]=8'h2C;
        mem[8'h2E]=8'h30;

        repeat(2) @(negedge clk); reset=0;
        while(mem[8'hD0] == 8'h00 && timeout < 500) begin
            @(negedge clk);
            timeout=timeout+1;
        end

        if(timeout >= 500) begin
            $display("jz: timeout");
            errors=errors+1;
        end else if(mem[8'hD0] !== 8'hAA) begin
            $display("jz: error  value=%02h", mem[8'hD0]);
            errors=errors+1;
        end else begin
            $display("jz: ok");
        end

        if(errors!=0) $display("jz test has error");
        sim_done = 1'b1;
    end
endmodule
