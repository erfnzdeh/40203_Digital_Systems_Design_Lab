// Top-level controller for the Lab 8 processor.
// It reads an instruction from memory, decodes the operands, starts the complex ALU and writes back the result.
module complex_processor #(
    parameter WIDTH = 8,
    parameter RESULT_WIDTH = 2*WIDTH + 1,
    parameter PROGRAM_LENGTH = 8
) (
    input                         clk,
    input                         reset,
    input                         start,

    output reg signed [RESULT_WIDTH-1:0] result_real,
    output reg signed [RESULT_WIDTH-1:0] result_imag,
    output reg                    valid,
    output reg                    overflow,
    output reg                    zero,
    output reg                    real_negative,
    output reg                    imag_negative,
    output reg [4:0]              result_pc,
    output                        busy,
    output reg                    done
);
    // Instruction format: opcode + real/imag fields for operand A and operand B.
    localparam INSTR_WIDTH = 4*WIDTH + 3;

    // Processor FSM stages. P_WAIT is important because some ALU instructions take several clocks.
    localparam P_IDLE   = 4'd0,
               P_FETCH  = 4'd1,
               P_DECODE = 4'd2,
               P_READ   = 4'd3,
               P_START  = 4'd4,
               P_WAIT   = 4'd5,
               P_WB     = 4'd6;

    // Registers between stages keep the fetched instruction and decoded operands stable.
    reg [3:0] state;
    reg [4:0] pc;
    reg [4:0] fetched_pc;
    wire [INSTR_WIDTH-1:0] instruction;
    reg  [INSTR_WIDTH-1:0] instruction_reg;

    reg [2:0] opcode_reg;
    reg signed [WIDTH-1:0] a_real_reg, a_imag_reg, b_real_reg, b_imag_reg;

    wire alu_start;
    wire signed [RESULT_WIDTH-1:0] alu_real, alu_imag;
    wire alu_valid, alu_overflow, alu_zero, alu_real_negative, alu_imag_negative, alu_busy;

    // Program memory is 32 words deep; PC selects the current instruction.
    instruction_memory #(
        .WIDTH(WIDTH), .DEPTH(32), .WORD_WIDTH(INSTR_WIDTH)
    ) IMEM (
        .address(pc), .data(instruction)
    );

    assign alu_start = (state == P_START);

    // The processor sends one start pulse to the ALU and waits for alu_valid before write-back.
    complex_alu_mc #(
        .WIDTH(WIDTH), .RESULT_WIDTH(RESULT_WIDTH)
    ) ALU (
        .clk(clk), .reset(reset), .start(alu_start), .opcode(opcode_reg),
        .a_real(a_real_reg), .a_imag(a_imag_reg),
        .b_real(b_real_reg), .b_imag(b_imag_reg),
        .result_real(alu_real), .result_imag(alu_imag),
        .valid(alu_valid), .overflow(alu_overflow), .zero(alu_zero),
        .real_negative(alu_real_negative), .imag_negative(alu_imag_negative),
        .busy(alu_busy)
    );

    assign busy = (state != P_IDLE);

    // Synchronous processor control and output registers.
    always @(posedge clk) begin
        if (reset) begin
            state <= P_IDLE;
            pc <= 0;
            fetched_pc <= 0;
            instruction_reg <= 0;
            opcode_reg <= 0;
            a_real_reg <= 0; a_imag_reg <= 0; b_real_reg <= 0; b_imag_reg <= 0;
            result_real <= 0; result_imag <= 0;
            valid <= 0; overflow <= 0; zero <= 1;
            real_negative <= 0; imag_negative <= 0;
            result_pc <= 0;
            done <= 0;
        end else begin
            valid <= 1'b0;

            case (state)
                P_IDLE: begin
                    if (start) begin
                        pc <= 0;
                        done <= 1'b0;
                        state <= P_FETCH;
                    end
                end

                // fetch instruction
                P_FETCH: begin
                    instruction_reg <= instruction;
                    fetched_pc <= pc;
                    state <= P_DECODE;
                end

                // decode opcode
                P_DECODE: begin
                    opcode_reg <= instruction_reg[4*WIDTH+2:4*WIDTH];
                    state <= P_READ;
                end

                // read operand fields
                P_READ: begin
                    a_real_reg <= instruction_reg[4*WIDTH-1:3*WIDTH];
                    a_imag_reg <= instruction_reg[3*WIDTH-1:2*WIDTH];
                    b_real_reg <= instruction_reg[2*WIDTH-1:WIDTH];
                    b_imag_reg <= instruction_reg[WIDTH-1:0];
                    state <= P_START;
                end

                // send a one-clock start pulse to the ALU
                P_START: begin
                    state <= P_WAIT;
                end

                // wait here until the current ALU operation is finished
                P_WAIT: begin
                    if (alu_valid)
                        state <= P_WB;
                end

                // write result and flags to the outputs
                P_WB: begin
                    result_real   <= alu_real;
                    result_imag   <= alu_imag;
                    overflow      <= alu_overflow;
                    zero          <= alu_zero;
                    real_negative <= alu_real_negative;
                    imag_negative <= alu_imag_negative;
                    result_pc     <= fetched_pc;
                    valid         <= 1'b1;

                    if (fetched_pc == PROGRAM_LENGTH-1) begin
                        done <= 1'b1;
                        state <= P_IDLE;
                    end else begin
                        pc <= pc + 1'b1;
                        state <= P_FETCH;
                    end
                end

                default: state <= P_IDLE;
            endcase
        end
    end
endmodule
