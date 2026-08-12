`timescale 1ns/1ps

module incubator_board_top (
    input  wire              CLOCK_IN,
    input  wire              RESET_N,
    input  wire [7:0]        SW_TEMP,

    output wire              LED_HEATER,
    output wire              LED_COOLER,
    output wire [3:0]        LED_RPS,
    output wire              LED_ERROR
);

    wire signed [7:0] signed_temperature;
    assign signed_temperature = SW_TEMP;

    incubator core (
        .clk          (CLOCK_IN),
        .reset_n      (RESET_N),
        .temperature  (signed_temperature),
        .heater_on    (LED_HEATER),
        .cooler_on    (LED_COOLER),
        .cooler_rps   (LED_RPS),
        .Error_Sensor (LED_ERROR)
    );

endmodule
