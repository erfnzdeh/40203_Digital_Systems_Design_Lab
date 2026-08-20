// Multi-cycle magnitude squared block: |z|^2 = real^2 + imag^2.
// One multiplier is reused for the two squares and the final result has zero imaginary part.
module magnitude_squared_mc #(
    parameter WIDTH = 8,
    parameter RESULT_WIDTH = 2*WIDTH + 1
) (
    input                         clk,
    input                         reset,
    input                         start,
    input  signed [WIDTH-1:0]     a_real,
    input  signed [WIDTH-1:0]     a_imag,
    output reg signed [RESULT_WIDTH-1:0] result,
    output reg                    valid,
    output reg                    busy
);
    // FSM order is a*a, b*b, sum, then valid.
    localparam S_IDLE = 3'd0, S_A2 = 3'd1, S_B2 = 3'd2,
               S_SUM  = 3'd3, S_DONE = 3'd4;
    reg [2:0] state;
    reg signed [WIDTH-1:0] ar, ai;
    reg signed [2*WIDTH-1:0] p_a2, p_b2;

    // Shared arithmetic signals for the two multiply cycles and the final addition.
    reg signed [WIDTH-1:0] mul_a, mul_b;
    wire signed [2*WIDTH-1:0] mul_y;
    wire signed [RESULT_WIDTH-1:0] a2_ext, b2_ext, sum_y;

    assign a2_ext = {{(RESULT_WIDTH-2*WIDTH){p_a2[2*WIDTH-1]}}, p_a2};
    assign b2_ext = {{(RESULT_WIDTH-2*WIDTH){p_b2[2*WIDTH-1]}}, p_b2};

    shared_multiplier #(.WIDTH(WIDTH)) U_MUL (
        .a(mul_a), .b(mul_b), .y(mul_y)
    );
    shared_addsub #(.WIDTH(RESULT_WIDTH)) U_ADD (
        .a(a2_ext), .b(b2_ext), .sub(1'b0), .y(sum_y)
    );

    // Choose a or b as the multiplier input depending on the current state.
    always @(*) begin
        mul_a = 0; mul_b = 0;
        case (state)
            S_A2: begin mul_a = ar; mul_b = ar; end
            S_B2: begin mul_a = ai; mul_b = ai; end
            default: ;
        endcase
    end

    // Save the two squared terms in registers before adding them.
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE; valid <= 0; busy <= 0; result <= 0;
            ar <= 0; ai <= 0; p_a2 <= 0; p_b2 <= 0;
        end else begin
            valid <= 1'b0;
            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        ar <= a_real; ai <= a_imag;
                        busy <= 1'b1;
                        state <= S_A2;
                    end
                end
                S_A2:   begin p_a2 <= mul_y; state <= S_B2; end
                S_B2:   begin p_b2 <= mul_y; state <= S_SUM; end
                S_SUM:  begin result <= sum_y; state <= S_DONE; end
                S_DONE: begin valid <= 1'b1; busy <= 1'b0; state <= S_IDLE; end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
