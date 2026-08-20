// Small combinational arithmetic blocks used as the shared hardware resources in the multi-cycle design.
module shared_addsub #(
    parameter WIDTH = 17
) (
    input  signed [WIDTH-1:0] a,
    input  signed [WIDTH-1:0] b,
    input                     sub,   // 0: a+b, 1: a-b
    output signed [WIDTH-1:0] y
);
    assign y = sub ? (a - b) : (a + b);
endmodule

// Signed WIDTH x WIDTH multiplier. Only one instance is used in the main complex ALU.
module shared_multiplier #(
    parameter WIDTH = 8
) (
    input  signed [WIDTH-1:0]     a,
    input  signed [WIDTH-1:0]     b,
    output signed [2*WIDTH-1:0]   y
);
    assign y = a * b;
endmodule
