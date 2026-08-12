`timescale 1ns/1ps


module incubator_tb_edges;

    reg clk;
    reg reset_n;
    reg signed [7:0] temperature;
    wire heater_on;
    wire cooler_on;
    wire [3:0] cooler_rps;
    wire Error_Sensor;
    integer errors;

    incubator dut (
        .clk          (clk),
        .reset_n      (reset_n),
        .temperature  (temperature),
        .heater_on    (heater_on),
        .cooler_on    (cooler_on),
        .cooler_rps   (cooler_rps),
        .Error_Sensor (Error_Sensor)
    );

    always #5 clk = ~clk;

    task apply_temp;
        input signed [7:0] t;
    begin
        temperature = t;
        // Hold long enough for both FSMs to settle across sequential states.
        repeat (3) @(posedge clk);
        #1;
    end
    endtask

    task check_expected;
        input exp_heater;
        input exp_cooler;
        input [3:0] exp_rps;
        input exp_error;
    begin
        if ((heater_on !== exp_heater) ||
            (cooler_on !== exp_cooler) ||
            (cooler_rps !== exp_rps) ||
            (Error_Sensor !== exp_error)) begin
            $display("[ERROR] T=%0d got H=%b C=%b RPS=%0d ERR=%b | expected H=%b C=%b RPS=%0d ERR=%b",
                     $signed(temperature), heater_on, cooler_on, cooler_rps, Error_Sensor,
                     exp_heater, exp_cooler, exp_rps, exp_error);
            errors = errors + 1;
        end
        else begin
            $display("[PASS]  T=%0d -> H=%b C=%b RPS=%0d ERR=%b",
                     $signed(temperature), heater_on, cooler_on, cooler_rps, Error_Sensor);
        end
    end
    endtask

    initial begin
        clk = 0;
        reset_n = 0;
        temperature = 8'sd20;
        errors = 0;

        #12;
        reset_n = 1;
        repeat (2) @(posedge clk);

        // Main FSM: equality must NOT trigger strict transitions.
        apply_temp(8'sd35); check_expected(0, 0, 0, 0);  // not >35
        apply_temp(8'sd36); check_expected(0, 1, 4, 0);  // enter cooling

        // Fan thresholds.
        apply_temp(8'sd40); check_expected(0, 1, 4, 0);  // not >40
        apply_temp(8'sd41); check_expected(0, 1, 6, 0);
        apply_temp(8'sd45); check_expected(0, 1, 6, 0);  // not >45
        apply_temp(8'sd46); check_expected(0, 1, 8, 0);
        apply_temp(8'sd40); check_expected(0, 1, 8, 0);  // not <40
        apply_temp(8'sd39); check_expected(0, 1, 6, 0);
        apply_temp(8'sd35); check_expected(0, 1, 6, 0);  // not <35
        apply_temp(8'sd34); check_expected(0, 1, 4, 0);
        apply_temp(8'sd25); check_expected(0, 1, 4, 0);  // not <25
        apply_temp(8'sd24); check_expected(0, 0, 0, 0);  // cooler OFF

        // Heater thresholds.
        apply_temp(8'sd15); check_expected(0, 0, 0, 0);  // not <15
        apply_temp(8'sd14); check_expected(1, 0, 0, 0);
        apply_temp(8'sd30); check_expected(1, 0, 0, 0);  // not >30
        apply_temp(8'sd31); check_expected(0, 0, 0, 0);

        // Sensor health boundaries.
        apply_temp(8'sd60);  check_expected(0, 1, 8, 0); // +60 is valid; cooling reaches 8 RPS
        temperature = 8'sd61; #1; check_expected(0, 0, 0, 1); // invalid high: immediate safe outputs
        // The fault must be held across at least one active edge, otherwise the
        // FSMs never leave their previous state and only the combinational
        // output override is exercised.
        repeat (3) @(posedge clk); #1;
        if (dut.main_state !== 2'b11) begin
            $display("[ERROR] Main FSM did not enter M_SAFE for the high fault.");
            errors = errors + 1;
        end
        apply_temp(8'sd20);  check_expected(0, 0, 0, 0); // recovery from SAFE -> IDLE

        apply_temp(-8'sd10); check_expected(1, 0, 0, 0); // -10 is valid and requires heating
        temperature = -8'sd11; #1; check_expected(0, 0, 0, 1); // invalid low
        repeat (3) @(posedge clk); #1;
        if (dut.main_state !== 2'b11) begin
            $display("[ERROR] Main FSM did not enter M_SAFE for the low fault.");
            errors = errors + 1;
        end
        apply_temp(8'sd20);  check_expected(0, 0, 0, 0); // recovery from SAFE -> IDLE

        // Heating hysteresis: once heating has started, it must persist until
        // the temperature actually exceeds 30 C, even at a comfortable 20 C.
        apply_temp(8'sd14); check_expected(1, 0, 0, 0);
        apply_temp(8'sd20); check_expected(1, 0, 0, 0);
        apply_temp(8'sd31); check_expected(0, 0, 0, 0);

        if (errors == 0)
            $display("ALL DIRECTED EDGE TESTS PASSED");
        else
            $display("DIRECTED TEST FINISHED WITH %0d ERROR(S)", errors);

        #20;
        $finish;
    end

endmodule
