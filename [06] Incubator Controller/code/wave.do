quietly WaveActivateNextPane {} 0
add wave -divider {INPUTS}
add wave -radix binary sim:/incubator_tb/clk
add wave -radix binary sim:/incubator_tb/reset_n
add wave -radix decimal sim:/incubator_tb/temperature
add wave -radix decimal sim:/incubator_tb/plant_temperature
add wave -radix decimal sim:/incubator_tb/external_heat_load
add wave -radix binary sim:/incubator_tb/fault_enable
add wave -divider {OUTPUTS}
add wave -radix binary sim:/incubator_tb/heater_on
add wave -radix binary sim:/incubator_tb/cooler_on
add wave -radix unsigned sim:/incubator_tb/cooler_rps
add wave -radix binary sim:/incubator_tb/Error_Sensor
add wave -divider {INTERNAL FSM STATES}
add wave -radix unsigned sim:/incubator_tb/dut/main_state
add wave -radix unsigned sim:/incubator_tb/dut/main_next_state
add wave -radix unsigned sim:/incubator_tb/dut/fan_state
add wave -radix unsigned sim:/incubator_tb/dut/fan_next_state
configure wave -namecolwidth 260
configure wave -valuecolwidth 100
configure wave -timelineunits ns
WaveRestoreZoom {0 ns} {3500 ns}
