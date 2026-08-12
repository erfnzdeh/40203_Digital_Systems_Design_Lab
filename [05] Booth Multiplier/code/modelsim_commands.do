vsim -voptargs=+acc work.BoothMultiplierTestbench

view wave

add wave sim:/BoothMultiplierTestbench/clk
add wave sim:/BoothMultiplierTestbench/str
add wave sim:/BoothMultiplierTestbench/multiplicand
add wave sim:/BoothMultiplierTestbench/multiplier
add wave sim:/BoothMultiplierTestbench/result
add wave sim:/BoothMultiplierTestbench/valid

add wave sim:/BoothMultiplierTestbench/dut/datapath/accumulator
add wave sim:/BoothMultiplierTestbench/dut/datapath/temp_multiplicand
add wave sim:/BoothMultiplierTestbench/dut/datapath/q_reg
add wave sim:/BoothMultiplierTestbench/dut/datapath/q_minus_one
add wave sim:/BoothMultiplierTestbench/dut/datapath/booth_register

add wave sim:/BoothMultiplierTestbench/dut/control/state
add wave sim:/BoothMultiplierTestbench/dut/control/bits_remaining
add wave sim:/BoothMultiplierTestbench/dut/control/booth_bits
add wave sim:/BoothMultiplierTestbench/dut/control/rightMost
add wave sim:/BoothMultiplierTestbench/dut/control/differences

add wave sim:/BoothMultiplierTestbench/dut/load
add wave sim:/BoothMultiplierTestbench/dut/arth
add wave sim:/BoothMultiplierTestbench/dut/shiftRight

run -all
wave zoom full
