`timescale 1ns/1ps

module UARTTop #(
    parameter integer TICKS_BIT = 2
)(
    input  wire       clk,
    input  wire       rstN,
    input  wire       new_data,
    input  wire [6:0] send_data,
    output wire       tx,
    output wire       busy,
    output wire [6:0] rec_data,
    output wire       rec_new_data,
    output wire       correct_data
);

    UARTSender #(
        .TICKS_BIT(TICKS_BIT)
    ) sender (
        .clk       (clk),
        .rstN      (rstN),
        .data_new  (new_data),
        .data_send (send_data),
        .tx        (tx),
        .busy      (busy)
    );

    // Internal loopback connects the transmitter output directly to the receiver.
    UARTReceiver #(
        .TICKS_BIT(TICKS_BIT)
    ) receiver (
        .clk          (clk),
        .rstN         (rstN),
        .rx           (tx),
        .data_rec     (rec_data),
        .data_new_rec (rec_new_data),
        .data_correct (correct_data)
    );

endmodule
