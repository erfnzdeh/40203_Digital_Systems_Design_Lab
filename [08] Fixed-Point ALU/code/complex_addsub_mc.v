// Complex add/sub block for two signed complex numbers.
// I use one shared adder and calculate the real and imaginary parts in separate clock cycles.
module complex_addsub_mc #(
    parameter WIDTH = 8,
    parameter RESULT_WIDTH = 2*WIDTH + 1
) (
    input                         clk,
    input                         reset,
    input                         start,
    input                         sub,          // 0:add, 1:subtract
    input  signed [WIDTH-1:0]     a_real,
    input  signed [WIDTH-1:0]     a_imag,
    input  signed [WIDTH-1:0]     b_real,
    input  signed [WIDTH-1:0]     b_imag,
    output reg signed [RESULT_WIDTH-1:0] result_real,
    output reg signed [RESULT_WIDTH-1:0] result_imag,
    output reg                    valid,
    output reg                    overflow,
    output reg                    busy
);
    // Small FSM: latch inputs, calculate real part, calculate imaginary part, then raise valid.
    localparam S_IDLE   = 2'd0;
    localparam S_REAL   = 2'd1;
    localparam S_IMAG   = 2'd2;
    localparam S_DONE   = 2'd3;

    reg [1:0] state;
    reg op_reg;
    reg signed [WIDTH-1:0] ar, ai, br, bi;
    reg ovf_temp;

    reg  signed [RESULT_WIDTH-1:0] add_a, add_b;
    wire signed [RESULT_WIDTH-1:0] add_y;

    // The same add/sub hardware is reused for both components.
    shared_addsub #(.WIDTH(RESULT_WIDTH)) U_ADD (
        .a(add_a), .b(add_b), .sub(op_reg), .y(add_y)
    );

    // Sign extension keeps negative WIDTH-bit operands correct at the wider result width.
    function signed [RESULT_WIDTH-1:0] sext_in;
        input signed [WIDTH-1:0] x;
        begin
            sext_in = {{(RESULT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
        end
    endfunction

    // Overflow is checked using the original WIDTH-bit signed result.
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

    // Select which component is connected to the shared adder in the current state.
    always @(*) begin
        add_a = 0;
        add_b = 0;
        case (state)
            S_REAL: begin add_a = sext_in(ar); add_b = sext_in(br); end
            S_IMAG: begin add_a = sext_in(ai); add_b = sext_in(bi); end
            default: begin add_a = 0; add_b = 0; end
        endcase
    end

    // Sequential part of the FSM. valid is only pulsed after both components are ready.
    always @(posedge clk) begin
        if (reset) begin
            state       <= S_IDLE;
            valid       <= 1'b0;
            busy        <= 1'b0;
            overflow    <= 1'b0;
            ovf_temp    <= 1'b0;
            result_real <= 0;
            result_imag <= 0;
            ar <= 0; ai <= 0; br <= 0; bi <= 0; op_reg <= 0;
        end else begin
            valid <= 1'b0;
            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        ar <= a_real; ai <= a_imag; br <= b_real; bi <= b_imag;
                        op_reg <= sub;
                        ovf_temp <= 1'b0;
                        overflow <= 1'b0;
                        busy <= 1'b1;
                        state <= S_REAL;
                    end
                end
                S_REAL: begin
                    result_real <= add_y;
                    if (op_reg)
                        ovf_temp <= sub_ovf(ar, br, add_y[WIDTH-1:0]);
                    else
                        ovf_temp <= add_ovf(ar, br, add_y[WIDTH-1:0]);
                    state <= S_IMAG;
                end
                S_IMAG: begin
                    result_imag <= add_y;
                    if (op_reg)
                        overflow <= ovf_temp | sub_ovf(ai, bi, add_y[WIDTH-1:0]);
                    else
                        overflow <= ovf_temp | add_ovf(ai, bi, add_y[WIDTH-1:0]);
                    state <= S_DONE;
                end
                S_DONE: begin
                    valid <= 1'b1;
                    busy  <= 1'b0;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
