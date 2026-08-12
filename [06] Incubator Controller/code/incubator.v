`timescale 1ns/1ps


module incubator (
    input  wire                    clk,
    input  wire                    reset_n,
    input  wire signed [7:0]       temperature,

    output reg                     heater_on,
    output reg                     cooler_on,
    output reg [3:0]               cooler_rps,
    output reg                     Error_Sensor
);

  
    localparam signed [7:0] TEMP_MIN = -8'sd10;
    localparam signed [7:0] TEMP_MAX =  8'sd60;

    wire sensor_valid;
    assign sensor_valid = (temperature >= TEMP_MIN) &&
                          (temperature <= TEMP_MAX);


    localparam [1:0] M_IDLE = 2'b00;
    localparam [1:0] M_COOL = 2'b01;
    localparam [1:0] M_HEAT = 2'b10;
    localparam [1:0] M_SAFE = 2'b11;

    reg [1:0] main_state;
    reg [1:0] main_next_state;


    localparam [2:0] F_OUT  = 3'd0;
    localparam [2:0] F_4    = 3'd1;
    localparam [2:0] F_6    = 3'd2;
    localparam [2:0] F_8    = 3'd3;
    localparam [2:0] F_SAFE = 3'd4;

    reg [2:0] fan_state;
    reg [2:0] fan_next_state;


    always @(*) begin
        main_next_state = main_state;

        // Invalid sensor data has the highest priority.
        if (!sensor_valid) begin
            main_next_state = M_SAFE;
        end
        else begin
            case (main_state)
                M_IDLE: begin
                    if (temperature > 8'sd35)
                        main_next_state = M_COOL;
                    else if (temperature < 8'sd15)
                        main_next_state = M_HEAT;
                    else
                        main_next_state = M_IDLE;
                end

                M_COOL: begin
                    if (temperature < 8'sd25)
                        main_next_state = M_IDLE;
                    else
                        main_next_state = M_COOL;
                end

                M_HEAT: begin
                    if (temperature > 8'sd30)
                        main_next_state = M_IDLE;
                    else
                        main_next_state = M_HEAT;
                end

                M_SAFE: begin
                    
                    if (temperature > 8'sd35)
                        main_next_state = M_COOL;
                    else if (temperature < 8'sd15)
                        main_next_state = M_HEAT;
                    else
                        main_next_state = M_IDLE;
                end

                default: begin
                    // Illegal internal state -> fail safe.
                    main_next_state = M_SAFE;
                end
            endcase
        end
    end

    
    always @(*) begin
        fan_next_state = fan_state;

        if (!sensor_valid) begin
            fan_next_state = F_SAFE;
        end
        else if (main_next_state != M_COOL) begin
           
            fan_next_state = F_OUT;
        end
        else begin
            case (fan_state)
                F_OUT: begin
                    fan_next_state = F_4;
                end

                F_4: begin
                    if (temperature > 8'sd40)
                        fan_next_state = F_6;
                    else
                        fan_next_state = F_4;
                end

                F_6: begin
                    if (temperature > 8'sd45)
                        fan_next_state = F_8;
                    else if (temperature < 8'sd35)
                        fan_next_state = F_4;
                    else
                        fan_next_state = F_6;
                end

                F_8: begin
                    if (temperature < 8'sd40)
                        fan_next_state = F_6;
                    else
                        fan_next_state = F_8;
                end

                F_SAFE: begin
                   
                    fan_next_state = F_4;
                end

                default: begin
                    fan_next_state = F_SAFE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // State registers - asynchronous active-low reset
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            main_state <= M_IDLE;
            fan_state  <= F_OUT;
        end
        else begin
            main_state <= main_next_state;
            fan_state  <= fan_next_state;
        end
    end

    // ------------------------------------------------------------------------
    // Output logic
    //
    // IMPORTANT SAFE-STATE DETAIL:
    // sensor_valid directly overrides the actuator outputs. Therefore, as soon
    // as an invalid sensor value appears, Heater and Cooler are forced OFF and
    // Error_Sensor becomes 1 without waiting for another clock edge. The FSMs
    // also enter their SAFE states at the next active clock edge.
    // ------------------------------------------------------------------------
    always @(*) begin
        heater_on   = 1'b0;
        cooler_on   = 1'b0;
        cooler_rps  = 4'd0;
        Error_Sensor = ~sensor_valid;

        if (reset_n && sensor_valid) begin
            case (main_state)
                M_COOL: begin
                    cooler_on = 1'b1;
                end

                M_HEAT: begin
                    heater_on = 1'b1;
                end

                default: begin
                    heater_on = 1'b0;
                    cooler_on = 1'b0;
                end
            endcase

            // Fan output is meaningful only when cooling is active.
            if (main_state == M_COOL) begin
                case (fan_state)
                    F_4: cooler_rps = 4'd4;
                    F_6: cooler_rps = 4'd6;
                    F_8: cooler_rps = 4'd8;
                    default: cooler_rps = 4'd0;
                endcase
            end
        end
    end

endmodule
