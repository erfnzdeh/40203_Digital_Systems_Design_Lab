// Main complex ALU used by the processor.
// The FSM reuses one multiplier and one add/sub unit so CMUL and MAG2 are done over several cycles.
module complex_alu_mc #(
    parameter WIDTH = 8,
    parameter RESULT_WIDTH = 2*WIDTH + 1
) (
    input                         clk,
    input                         reset,
    input                         start,
    input      [2:0]              opcode,
    input  signed [WIDTH-1:0]     a_real,
    input  signed [WIDTH-1:0]     a_imag,
    input  signed [WIDTH-1:0]     b_real,
    input  signed [WIDTH-1:0]     b_imag,

    output reg signed [RESULT_WIDTH-1:0] result_real,
    output reg signed [RESULT_WIDTH-1:0] result_imag,
    output reg                    valid,
    output reg                    overflow,
    output reg                    zero,
    output reg                    real_negative,
    output reg                    imag_negative,
    output reg                    busy
);
    // Opcodes used by the instruction decoder.
    localparam OP_CADD = 3'b000,
               OP_CSUB = 3'b001,
               OP_CMUL = 3'b010,
               OP_CONJ = 3'b011,
               OP_MAG2 = 3'b100,
               OP_NOP  = 3'b101;

    // One state is used for each step that needs the shared arithmetic hardware.
    localparam ST_IDLE       = 5'd0,
               ST_ADD_R      = 5'd1,
               ST_ADD_I      = 5'd2,
               ST_SUB_R      = 5'd3,
               ST_SUB_I      = 5'd4,
               ST_MUL_AC     = 5'd5,
               ST_MUL_BD     = 5'd6,
               ST_MUL_AD     = 5'd7,
               ST_MUL_BC     = 5'd8,
               ST_MUL_REAL   = 5'd9,
               ST_MUL_IMAG   = 5'd10,
               ST_CONJ_NEG   = 5'd11,
               ST_MAG_A2     = 5'd12,
               ST_MAG_B2     = 5'd13,
               ST_MAG_SUM    = 5'd14,
               ST_FINISH     = 5'd15;

    // Input and intermediate registers are kept because some operations need multiple clocks.
    reg [4:0] state;
    reg [2:0] op_reg;
    reg signed [WIDTH-1:0] ar, ai, br, bi;
    reg signed [2*WIDTH-1:0] p_ac, p_bd, p_ad, p_bc, p_a2, p_b2;
    reg signed [RESULT_WIDTH-1:0] temp_real, temp_imag;
    reg overflow_temp;

    // Only one multiplier is instantiated. Its inputs change with the FSM state.
    reg  signed [WIDTH-1:0] mul_a, mul_b;
    wire signed [2*WIDTH-1:0] mul_y;
    shared_multiplier #(.WIDTH(WIDTH)) U_SHARED_MUL (
        .a(mul_a), .b(mul_b), .y(mul_y)
    );

    // The same add/sub unit is used for CADD, CSUB, the final CMUL sums and MAG2.
    reg  signed [RESULT_WIDTH-1:0] add_a, add_b;
    reg                            add_sub;
    wire signed [RESULT_WIDTH-1:0] add_y;
    shared_addsub #(.WIDTH(RESULT_WIDTH)) U_SHARED_ADD (
        .a(add_a), .b(add_b), .sub(add_sub), .y(add_y)
    );

    // Helper functions keep the signed values at a common result width.
    function signed [RESULT_WIDTH-1:0] sext_in;
        input signed [WIDTH-1:0] x;
        begin
            sext_in = {{(RESULT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
        end
    endfunction

    function signed [RESULT_WIDTH-1:0] sext_prod;
        input signed [2*WIDTH-1:0] x;
        begin
            sext_prod = {{(RESULT_WIDTH-2*WIDTH){x[2*WIDTH-1]}}, x};
        end
    endfunction

    // Signed overflow logic is only needed for the WIDTH-bit add/sub operations.
    function add_ovf;
        input signed [WIDTH-1:0] x;
        input signed [WIDTH-1:0] y;
        input signed [WIDTH-1:0] r;
        begin
            add_ovf = (~(x[WIDTH-1] ^ y[WIDTH-1])) & (r[WIDTH-1] ^ x[WIDTH-1]);
        end
    endfunction

    function sub_ovf;
        input signed [WIDTH-1:0] x;
        input signed [WIDTH-1:0] y;
        input signed [WIDTH-1:0] r;
        begin
            sub_ovf = (x[WIDTH-1] ^ y[WIDTH-1]) & (r[WIDTH-1] ^ x[WIDTH-1]);
        end
    endfunction

    // This combinational block works like the input muxes of the shared datapath.
    always @(*) begin
        mul_a   = 0;
        mul_b   = 0;
        add_a   = 0;
        add_b   = 0;
        add_sub = 1'b0;

        case (state)
            ST_ADD_R: begin add_a = sext_in(ar); add_b = sext_in(br); add_sub = 1'b0; end
            ST_ADD_I: begin add_a = sext_in(ai); add_b = sext_in(bi); add_sub = 1'b0; end
            ST_SUB_R: begin add_a = sext_in(ar); add_b = sext_in(br); add_sub = 1'b1; end
            ST_SUB_I: begin add_a = sext_in(ai); add_b = sext_in(bi); add_sub = 1'b1; end

            ST_MUL_AC: begin mul_a = ar; mul_b = br; end
            ST_MUL_BD: begin mul_a = ai; mul_b = bi; end
            ST_MUL_AD: begin mul_a = ar; mul_b = bi; end
            ST_MUL_BC: begin mul_a = ai; mul_b = br; end
            ST_MUL_REAL: begin add_a = sext_prod(p_ac); add_b = sext_prod(p_bd); add_sub = 1'b1; end
            ST_MUL_IMAG: begin add_a = sext_prod(p_ad); add_b = sext_prod(p_bc); add_sub = 1'b0; end

            ST_CONJ_NEG: begin add_a = 0; add_b = sext_in(ai); add_sub = 1'b1; end

            ST_MAG_A2: begin mul_a = ar; mul_b = ar; end
            ST_MAG_B2: begin mul_a = ai; mul_b = ai; end
            ST_MAG_SUM: begin add_a = sext_prod(p_a2); add_b = sext_prod(p_b2); add_sub = 1'b0; end
            default: ;
        endcase
    end

    // Main controller: start latches the operands, then the FSM advances one step per clock.
    always @(posedge clk) begin
        if (reset) begin
            state         <= ST_IDLE;
            op_reg        <= OP_NOP;
            ar <= 0; ai <= 0; br <= 0; bi <= 0;
            p_ac <= 0; p_bd <= 0; p_ad <= 0; p_bc <= 0; p_a2 <= 0; p_b2 <= 0;
            temp_real     <= 0;
            temp_imag     <= 0;
            overflow_temp <= 1'b0;
            result_real   <= 0;
            result_imag   <= 0;
            valid         <= 1'b0;
            overflow      <= 1'b0;
            zero          <= 1'b1;
            real_negative <= 1'b0;
            imag_negative <= 1'b0;
            busy          <= 1'b0;
        end else begin
            valid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        ar <= a_real; ai <= a_imag; br <= b_real; bi <= b_imag;
                        op_reg <= opcode;
                        temp_real <= 0;
                        temp_imag <= 0;
                        overflow_temp <= 1'b0;
                        overflow <= 1'b0;
                        busy <= 1'b1;

                        case (opcode)
                            OP_CADD: state <= ST_ADD_R;
                            OP_CSUB: state <= ST_SUB_R;
                            OP_CMUL: state <= ST_MUL_AC;
                            OP_CONJ: begin
                                temp_real <= sext_in(a_real);
                                state <= ST_CONJ_NEG;
                            end
                            OP_MAG2: begin
                                temp_imag <= 0;
                                state <= ST_MAG_A2;
                            end
                            default: begin
                                temp_real <= 0;
                                temp_imag <= 0;
                                state <= ST_FINISH;
                            end
                        endcase
                    end
                end

                ST_ADD_R: begin
                    temp_real <= add_y;
                    overflow_temp <= add_ovf(ar, br, add_y[WIDTH-1:0]);
                    state <= ST_ADD_I;
                end
                ST_ADD_I: begin
                    temp_imag <= add_y;
                    overflow_temp <= overflow_temp | add_ovf(ai, bi, add_y[WIDTH-1:0]);
                    state <= ST_FINISH;
                end

                ST_SUB_R: begin
                    temp_real <= add_y;
                    overflow_temp <= sub_ovf(ar, br, add_y[WIDTH-1:0]);
                    state <= ST_SUB_I;
                end
                ST_SUB_I: begin
                    temp_imag <= add_y;
                    overflow_temp <= overflow_temp | sub_ovf(ai, bi, add_y[WIDTH-1:0]);
                    state <= ST_FINISH;
                end

                // Complex multiply: ac, bd, ad and bc are calculated one after another.
                ST_MUL_AC: begin p_ac <= mul_y; state <= ST_MUL_BD; end
                ST_MUL_BD: begin p_bd <= mul_y; state <= ST_MUL_AD; end
                ST_MUL_AD: begin p_ad <= mul_y; state <= ST_MUL_BC; end
                ST_MUL_BC: begin p_bc <= mul_y; state <= ST_MUL_REAL; end
                ST_MUL_REAL: begin temp_real <= add_y; state <= ST_MUL_IMAG; end
                ST_MUL_IMAG: begin temp_imag <= add_y; state <= ST_FINISH; end

                ST_CONJ_NEG: begin
                    temp_imag <= add_y;
                    state <= ST_FINISH;
                end

                // Magnitude squared also reuses the multiplier: a*a, b*b, then one addition.
                ST_MAG_A2: begin p_a2 <= mul_y; state <= ST_MAG_B2; end
                ST_MAG_B2: begin p_b2 <= mul_y; state <= ST_MAG_SUM; end
                ST_MAG_SUM: begin
                    temp_real <= add_y;
                    temp_imag <= 0;
                    state <= ST_FINISH;
                end

                // Results and status flags are updated together when the operation is complete.
                ST_FINISH: begin
                    result_real   <= temp_real;
                    result_imag   <= temp_imag;
                    overflow      <= overflow_temp;
                    zero          <= (temp_real == 0) && (temp_imag == 0);
                    real_negative <= temp_real[RESULT_WIDTH-1];
                    imag_negative <= temp_imag[RESULT_WIDTH-1];
                    valid         <= 1'b1;
                    busy          <= 1'b0;
                    state         <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
