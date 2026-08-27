`timescale 1ns/1ps

// 8 bit stack CPU
// opcode is stored in the high nibble in this project
module stack_cpu (
    input              clk,
    input              reset,

    output reg [7:0]    mem_addr,
    output reg [7:0]    mem_wdata,
    output reg          mem_we,
    input      [7:0]    mem_rdata,

    output reg          flag_s,
    output reg          flag_z,
    output reg          instr_done,

    output     [7:0]    debug_pc,
    output     [3:0]    debug_sp,
    output     [7:0]    debug_top,
    output     [7:0]    debug_second
);
    localparam OP_PUSHC = 4'b0000,
               OP_PUSH  = 4'b0001,
               OP_POP   = 4'b0010,
               OP_JUMP  = 4'b0011,
               OP_JZ    = 4'b0100,
               OP_JS    = 4'b0101,
               OP_ADD   = 4'b0110,
               OP_SUB   = 4'b0111,
               OP_SWAP  = 4'b1000,
               OP_SHL   = 4'b1001,
               OP_CMP   = 4'b1010;

    localparam S_FETCH         = 5'd0,
               S_DECODE        = 5'd1,
               S_FETCH_OPERAND = 5'd2,
               S_PUSHC         = 5'd3,
               S_PUSH_READ     = 5'd4,
               S_POP_WRITE     = 5'd5,
               S_JUMP          = 5'd6,
               S_JZ            = 5'd7,
               S_JS            = 5'd8,
               S_ADD           = 5'd9,
               S_SUB           = 5'd10,
               S_SWAP          = 5'd11,
               S_SHL           = 5'd12,
               S_CMP           = 5'd13;

    reg [4:0] state;
    reg [7:0] pc;
    reg [7:0] ir;
    reg [7:0] operand;
    reg [3:0] sp;
    reg [7:0] stack [0:7];
    integer i;

    wire [7:0] top_a;
    wire [7:0] second_b;
    wire [7:0] add_result;
    wire [7:0] sub_result;
    wire [7:0] shl_result;

    assign top_a       = (sp >= 1) ? stack[sp-1'b1] : 8'h00;
    assign second_b    = (sp >= 2) ? stack[sp-2'd2]  : 8'h00;
    assign add_result  = second_b + top_a;
    assign sub_result  = second_b - top_a;
    assign shl_result  = {top_a[6:0], 1'b0};

    assign debug_pc     = pc;
    assign debug_sp     = sp;
    assign debug_top    = top_a;
    assign debug_second = second_b;

    // memory bus
    always @(*) begin
        mem_addr  = 8'h00;
        mem_wdata = 8'h00;
        mem_we    = 1'b0;

        case (state)
            S_FETCH: begin
                mem_addr = pc;
            end

            S_FETCH_OPERAND: begin
                mem_addr = pc;
            end

            S_PUSH_READ: begin
                mem_addr = operand;
            end

            S_POP_WRITE: begin
                mem_addr  = operand;
                mem_wdata = top_a;
                mem_we    = (sp != 0);
            end

            default: begin
                mem_addr  = 8'h00;
                mem_wdata = 8'h00;
                mem_we    = 1'b0;
            end
        endcase
    end

    // control unit
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= S_FETCH;
            pc         <= 8'h00;
            ir         <= 8'h00;
            operand    <= 8'h00;
            sp         <= 4'd0;
            flag_s     <= 1'b0;
            flag_z     <= 1'b0;
            instr_done <= 1'b0;
            for (i = 0; i < 8; i = i + 1)
                stack[i] <= 8'h00;
        end else begin
            instr_done <= 1'b0;

            case (state)
                S_FETCH: begin
                    ir    <= mem_rdata;
                    pc    <= pc + 1'b1;
                    state <= S_DECODE;
                end

                S_DECODE: begin
                    case (ir[7:4])
                        OP_PUSHC, OP_PUSH, OP_POP: state <= S_FETCH_OPERAND;
                        OP_JUMP: state <= S_JUMP;
                        OP_JZ:   state <= S_JZ;
                        OP_JS:   state <= S_JS;
                        OP_ADD:  state <= S_ADD;
                        OP_SUB:  state <= S_SUB;
                        OP_SWAP: state <= S_SWAP;
                        OP_SHL:  state <= S_SHL;
                        OP_CMP:  state <= S_CMP;
                        default: begin
                            // reserved opcode
                            state      <= S_FETCH;
                            instr_done <= 1'b1;
                        end
                    endcase
                end

                S_FETCH_OPERAND: begin
                    operand <= mem_rdata;
                    pc      <= pc + 1'b1;
                    case (ir[7:4])
                        OP_PUSHC: state <= S_PUSHC;
                        OP_PUSH:  state <= S_PUSH_READ;
                        OP_POP:   state <= S_POP_WRITE;
                        default:  state <= S_FETCH;
                    endcase
                end

                S_PUSHC: begin
                    if (sp < 8) begin
                        stack[sp] <= operand;
                        sp        <= sp + 1'b1;
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                S_PUSH_READ: begin
                    if (sp < 8) begin
                        stack[sp] <= mem_rdata;
                        sp        <= sp + 1'b1;
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                S_POP_WRITE: begin
                    if (sp != 0)
                        sp <= sp - 1'b1;
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                S_JUMP: begin
                    if (sp != 0) begin
                        pc <= top_a;
                        sp <= sp - 1'b1;
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                S_JZ: begin
                    if (sp != 0) begin
                        if (flag_z)
                            pc <= top_a;
                        sp <= sp - 1'b1;
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                S_JS: begin
                    if (sp != 0) begin
                        if (flag_s)
                            pc <= top_a;
                        sp <= sp - 1'b1;
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                S_ADD: begin
                    if (sp >= 2) begin
                        stack[sp-2'd2] <= add_result;
                        sp             <= sp - 1'b1;
                        flag_z         <= (add_result == 8'h00);
                        flag_s         <= add_result[7];
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                // B - A
                S_SUB: begin
                    if (sp >= 2) begin
                        stack[sp-2'd2] <= sub_result;
                        sp             <= sp - 1'b1;
                        flag_z         <= (sub_result == 8'h00);
                        flag_s         <= sub_result[7];
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                S_SWAP: begin
                    if (sp >= 2) begin
                        stack[sp-1'b1] <= second_b;
                        stack[sp-2'd2] <= top_a;
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                S_SHL: begin
                    if (sp >= 1)
                        stack[sp-1'b1] <= shl_result;
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                // compare B-A, stack does not change
                S_CMP: begin
                    if (sp >= 2) begin
                        flag_z <= (sub_result == 8'h00);
                        flag_s <= sub_result[7];
                    end
                    state      <= S_FETCH;
                    instr_done <= 1'b1;
                end

                default: begin
                    state <= S_FETCH;
                end
            endcase
        end
    end
endmodule
