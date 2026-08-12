`timescale 1ns/1ps


module incubator_tb;

    reg clk;
    reg reset_n;


    integer plant_temperature;
    integer external_heat_load;
    integer delta_temperature;
    integer simulated_minute;
    integer errors;


    reg fault_enable;
    reg signed [7:0] fault_temperature;

    wire signed [7:0] temperature;
    wire heater_on;
    wire cooler_on;
    wire [3:0] cooler_rps;
    wire Error_Sensor;

    assign temperature = fault_enable ? fault_temperature : plant_temperature;

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


    always begin
        #100;

        if (reset_n) begin
            delta_temperature = external_heat_load;

            if (heater_on)
                delta_temperature = delta_temperature + 3;

            if (cooler_on) begin
                case (cooler_rps)
                    4'd4: delta_temperature = delta_temperature - 1;
                    4'd6: delta_temperature = delta_temperature - 2;
                    4'd8: delta_temperature = delta_temperature - 6;
                    default: delta_temperature = delta_temperature;
                endcase
            end

            plant_temperature = plant_temperature + delta_temperature;

     
            if (plant_temperature > 60)
                plant_temperature = 60;
            else if (plant_temperature < -10)
                plant_temperature = -10;

            simulated_minute = simulated_minute + 1;

            $display("minute=%0d  plantT=%0d  sensedT=%0d  H=%b C=%b RPS=%0d ERR=%b extHeat=%0d",
                     simulated_minute, plant_temperature, $signed(temperature),
                     heater_on, cooler_on, cooler_rps, Error_Sensor,
                     external_heat_load);
        end
    end

   
    task check_outputs_safe;
    begin
        if ((Error_Sensor !== 1'b1) ||
            (heater_on !== 1'b0) ||
            (cooler_on !== 1'b0) ||
            (cooler_rps !== 4'd0)) begin
            $display("[ERROR] Safe-state outputs are incorrect at time %0t", $time);
            errors = errors + 1;
        end
        else begin
            $display("[PASS] Safe-state outputs are correct at time %0t", $time);
        end
    end
    endtask


    initial begin
        clk               = 1'b0;
        reset_n           = 1'b0;
        plant_temperature = 10;   // cold start -> heater must turn ON
        external_heat_load = 0;
        simulated_minute  = 0;
        fault_enable      = 1'b0;
        fault_temperature = 8'sd0;
        errors            = 0;

        $display("============================================================");
        $display("Experiment 6 smart closed-loop simulation started");
        $display("============================================================");


        #27;
        reset_n = 1'b1;


        wait (heater_on === 1'b1);
        $display("[PASS] Heater activated automatically. T=%0d", $signed(temperature));


        wait (heater_on === 1'b0);
        $display("[PASS] Heater turned OFF after crossing 30 C. T=%0d", $signed(temperature));

        external_heat_load = 4;
        $display("[INFO] External heat load applied: +4 C/min");


        wait (cooler_on === 1'b1);
        wait (cooler_rps == 4'd4);
        $display("[PASS] Cooler activated and fan entered 4 RPS.");


        wait (cooler_rps == 4'd6);
        $display("[PASS] Fan increased to 6 RPS.");

        wait (cooler_rps == 4'd8);
        $display("[PASS] Fan increased to 8 RPS.");


        external_heat_load = 0;
        $display("[INFO] External heat load removed.");

        wait (cooler_rps == 4'd6);
        $display("[PASS] Fan decreased from 8 to 6 RPS.");

        wait (cooler_rps == 4'd4);
        $display("[PASS] Fan decreased from 6 to 4 RPS.");

        wait (cooler_on === 1'b0);
        if (cooler_rps !== 4'd0) begin
            $display("[ERROR] Fan must be OUT when cooler turns OFF.");
            errors = errors + 1;
        end
        else begin
            $display("[PASS] Cooler turned OFF below 25 C and fan returned OUT.");
        end

        #20;
        fault_temperature = 8'sd70;
        fault_enable = 1'b1;
        #1;
        $display("[INFO] Injected sensor fault: +70 C");
        check_outputs_safe;


        #40;
        if (dut.main_state !== 2'b11) begin
            $display("[ERROR] Main FSM did not enter M_SAFE for +70 C.");
            errors = errors + 1;
        end
        else begin
            $display("[PASS] Main FSM entered M_SAFE for +70 C.");
        end

        fault_enable = 1'b0;
        #30;
        if (Error_Sensor !== 1'b0) begin
            $display("[ERROR] Error_Sensor did not clear after valid recovery.");
            errors = errors + 1;
        end
        else begin
            $display("[PASS] Sensor recovered from high fault.");
        end

  
        fault_temperature = -8'sd20;
        fault_enable = 1'b1;
        #1;
        $display("[INFO] Injected sensor fault: -20 C");
        check_outputs_safe;

        #40;
        if (dut.main_state !== 2'b11) begin
            $display("[ERROR] Main FSM did not enter M_SAFE for -20 C.");
            errors = errors + 1;
        end
        else begin
            $display("[PASS] Main FSM entered M_SAFE for -20 C.");
        end

        fault_enable = 1'b0;
        #30;

        if (errors == 0) begin
            $display("============================================================");
            $display("ALL AUTOMATIC CLOSED-LOOP TESTS PASSED");
            $display("============================================================");
        end
        else begin
            $display("============================================================");
            $display("SIMULATION FINISHED WITH %0d ERROR(S)", errors);
            $display("============================================================");
        end

        #20;
        $finish;
    end


    initial begin
        #10000;
        $display("[FATAL] Testbench timeout - a required state transition was not reached.");
        $finish;
    end

endmodule
