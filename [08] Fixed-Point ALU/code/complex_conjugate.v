// Complex conjugate block: keeps the real part and changes the sign of the imaginary part.
// Negation is implemented with the same add/sub style used in the rest of the design (0 - imag).
module complex_conjugate #(
    parameter WIDTH = 8,
    parameter RESULT_WIDTH = 2*WIDTH + 1
) (
    input                         clk,
    input                         reset,
    input                         start,
    input  signed [WIDTH-1:0]     a_real,
    input  signed [WIDTH-1:0]     a_imag,
    output reg signed [RESULT_WIDTH-1:0] result_real,
    output reg signed [RESULT_WIDTH-1:0] result_imag,
    output reg                    valid,
    output reg                    busy
);
    // A short FSM is used so the interface is the same start/busy/valid style as the other blocks.
    localparam S_IDLE = 2'd0, S_NEG = 2'd1, S_DONE = 2'd2;
    reg [1:0] state;
    reg signed [WIDTH-1:0] imag_reg;

    // Extend the imaginary input before negating it at RESULT_WIDTH.
    wire signed [RESULT_WIDTH-1:0] imag_ext;
    wire signed [RESULT_WIDTH-1:0] neg_imag;
    assign imag_ext = {{(RESULT_WIDTH-WIDTH){imag_reg[WIDTH-1]}}, imag_reg};

    shared_addsub #(.WIDTH(RESULT_WIDTH)) U_ADD (
        .a({RESULT_WIDTH{1'b0}}), .b(imag_ext), .sub(1'b1), .y(neg_imag)
    );

    // Inputs are accepted in IDLE and valid is pulsed for one clock in the DONE state.
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE; valid <= 0; busy <= 0;
            result_real <= 0; result_imag <= 0; imag_reg <= 0;
        end else begin
            valid <= 1'b0;
            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        result_real <= {{(RESULT_WIDTH-WIDTH){a_real[WIDTH-1]}}, a_real};
                        imag_reg <= a_imag;
                        busy <= 1'b1;
                        state <= S_NEG;
                    end
                end
                S_NEG: begin result_imag <= neg_imag; state <= S_DONE; end
                S_DONE: begin valid <= 1'b1; busy <= 1'b0; state <= S_IDLE; end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
