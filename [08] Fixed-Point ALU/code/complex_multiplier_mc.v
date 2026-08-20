// Multi-cycle complex multiplier.
// Instead of four multipliers, one multiplier is reused for ac, bd, ad and bc.
module complex_multiplier_mc #(
    parameter WIDTH = 8,
    parameter RESULT_WIDTH = 2*WIDTH + 1
) (
    input                         clk,
    input                         reset,
    input                         start,
    input  signed [WIDTH-1:0]     a_real,
    input  signed [WIDTH-1:0]     a_imag,
    input  signed [WIDTH-1:0]     b_real,
    input  signed [WIDTH-1:0]     b_imag,
    output reg signed [RESULT_WIDTH-1:0] result_real,
    output reg signed [RESULT_WIDTH-1:0] result_imag,
    output reg                    valid,
    output reg                    busy
);
    // States follow the calculation order: four products, real subtraction, imaginary addition, done.
    localparam S_IDLE = 4'd0, S_AC = 4'd1, S_BD = 4'd2,
               S_AD   = 4'd3, S_BC = 4'd4, S_REAL = 4'd5,
               S_IMAG = 4'd6, S_DONE = 4'd7;

    reg [3:0] state;
    reg signed [WIDTH-1:0] ar, ai, br, bi;
    reg signed [2*WIDTH-1:0] p_ac, p_bd, p_ad, p_bc;

    // Shared multiplier and shared add/sub datapath.
    reg  signed [WIDTH-1:0] mul_a, mul_b;
    wire signed [2*WIDTH-1:0] mul_y;
    reg  signed [RESULT_WIDTH-1:0] add_a, add_b;
    reg  add_sub;
    wire signed [RESULT_WIDTH-1:0] add_y;

    shared_multiplier #(.WIDTH(WIDTH)) U_MUL (
        .a(mul_a), .b(mul_b), .y(mul_y)
    );
    shared_addsub #(.WIDTH(RESULT_WIDTH)) U_ADD (
        .a(add_a), .b(add_b), .sub(add_sub), .y(add_y)
    );

    // Products are sign-extended before the final add/sub operation.
    function signed [RESULT_WIDTH-1:0] sext_prod;
        input signed [2*WIDTH-1:0] x;
        begin
            sext_prod = {{(RESULT_WIDTH-2*WIDTH){x[2*WIDTH-1]}}, x};
        end
    endfunction

    // Mux the required operands onto the shared units according to the current state.
    always @(*) begin
        mul_a = 0; mul_b = 0;
        add_a = 0; add_b = 0; add_sub = 1'b0;
        case (state)
            S_AC:   begin mul_a = ar; mul_b = br; end
            S_BD:   begin mul_a = ai; mul_b = bi; end
            S_AD:   begin mul_a = ar; mul_b = bi; end
            S_BC:   begin mul_a = ai; mul_b = br; end
            S_REAL: begin add_a = sext_prod(p_ac); add_b = sext_prod(p_bd); add_sub = 1'b1; end
            S_IMAG: begin add_a = sext_prod(p_ad); add_b = sext_prod(p_bc); add_sub = 1'b0; end
            default: ;
        endcase
    end

    // Store each partial product in a register and move to the next calculation step.
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE; valid <= 0; busy <= 0;
            result_real <= 0; result_imag <= 0;
            ar <= 0; ai <= 0; br <= 0; bi <= 0;
            p_ac <= 0; p_bd <= 0; p_ad <= 0; p_bc <= 0;
        end else begin
            valid <= 1'b0;
            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        ar <= a_real; ai <= a_imag; br <= b_real; bi <= b_imag;
                        busy <= 1'b1;
                        state <= S_AC;
                    end
                end
                S_AC:   begin p_ac <= mul_y; state <= S_BD; end
                S_BD:   begin p_bd <= mul_y; state <= S_AD; end
                S_AD:   begin p_ad <= mul_y; state <= S_BC; end
                S_BC:   begin p_bc <= mul_y; state <= S_REAL; end
                S_REAL: begin result_real <= add_y; state <= S_IMAG; end
                S_IMAG: begin result_imag <= add_y; state <= S_DONE; end
                S_DONE: begin valid <= 1'b1; busy <= 1'b0; state <= S_IDLE; end
            endcase
        end
    end
endmodule
