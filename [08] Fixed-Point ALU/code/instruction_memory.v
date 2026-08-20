// Simple 32-word instruction memory used by the processor.
// I initialize the test program in Verilog so ModelSim and Quartus use the same instruction contents.
module instruction_memory #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter WORD_WIDTH = 4*WIDTH + 3
) (
    input      [4:0] address,
    output     [WORD_WIDTH-1:0] data
);
    localparam OP_CADD = 3'b000,
               OP_CSUB = 3'b001,
               OP_CMUL = 3'b010,
               OP_CONJ = 3'b011,
               OP_MAG2 = 3'b100,
               OP_NOP  = 3'b101;

    reg [WORD_WIDTH-1:0] mem [0:DEPTH-1];
    integer i;

    // Pack opcode and four signed operand fields into one memory word.
    function [WORD_WIDTH-1:0] pack;
        input [2:0] op;
        input signed [WIDTH-1:0] ar;
        input signed [WIDTH-1:0] ai;
        input signed [WIDTH-1:0] br;
        input signed [WIDTH-1:0] bi;
        begin
            pack = {op, ar, ai, br, bi};
        end
    endfunction

    // Unused locations are cleared first, then the test instructions are written below.
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = pack(OP_NOP, 0, 0, 0, 0);

        // test program used in the final processor testbench
        mem[0] = pack(OP_CADD,   3,   4,   5,   2);   // (3+j4)+(5+j2) = 8+j6
        mem[1] = pack(OP_CADD,  -3,  -4,  -5,  -2);   // negative + negative = -8-j6
        mem[2] = pack(OP_CSUB,   2,   3,   7,   8);   // = -5-j5
        mem[3] = pack(OP_CMUL,   2,   3,  -4,   5);   // = -23-j2
        mem[4] = pack(OP_CONJ,  -6,   7,   0,   0);   // = -6-j7
        mem[5] = pack(OP_MAG2,   3,  -4,   0,   0);   // = 25+j0
        mem[6] = pack(OP_CADD,   5,  -5,  -5,   5);   // = 0+j0 (zero flag)
        mem[7] = pack(OP_CADD, 127,   0,   1,   0);   // = 128+j0 (8-bit overflow flag)
    end

    assign data = mem[address];
endmodule
