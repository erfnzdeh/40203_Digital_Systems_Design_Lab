vlog TCAM.v TB.v
vsim work.TB
add wave -r sim:/TB/*
add wave -r sim:/TB/dut/*
run -all
wave zoom full
