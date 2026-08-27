`timescale 1ns/1ps

// hex to 7-seg, order: abcdefg
module sevenseg_hex #(
    parameter ACTIVE_LOW = 1
) (
    input      [3:0] hex,
    output     [6:0] seg
);
    reg [6:0] active_high;

    always @(*) begin
        case (hex)
            4'h0: active_high = 7'b1111110;
            4'h1: active_high = 7'b0110000;
            4'h2: active_high = 7'b1101101;
            4'h3: active_high = 7'b1111001;
            4'h4: active_high = 7'b0110011;
            4'h5: active_high = 7'b1011011;
            4'h6: active_high = 7'b1011111;
            4'h7: active_high = 7'b1110000;
            4'h8: active_high = 7'b1111111;
            4'h9: active_high = 7'b1111011;
            4'hA: active_high = 7'b1110111;
            4'hB: active_high = 7'b0011111;
            4'hC: active_high = 7'b1001110;
            4'hD: active_high = 7'b0111101;
            4'hE: active_high = 7'b1001111;
            4'hF: active_high = 7'b1000111;
            default: active_high = 7'b0000000;
        endcase
    end

    assign seg = ACTIVE_LOW ? ~active_high : active_high;
endmodule
