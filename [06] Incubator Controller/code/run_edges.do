transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work
vlog ../src/incubator.v
vlog incubator_tb_edges.v
vsim -voptargs=+acc work.incubator_tb_edges
add wave -radix decimal sim:/incubator_tb_edges/temperature
add wave sim:/incubator_tb_edges/heater_on
add wave sim:/incubator_tb_edges/cooler_on
add wave -radix unsigned sim:/incubator_tb_edges/cooler_rps
add wave sim:/incubator_tb_edges/Error_Sensor
add wave -radix unsigned sim:/incubator_tb_edges/dut/main_state
add wave -radix unsigned sim:/incubator_tb_edges/dut/fan_state
run -all
wave zoom full
