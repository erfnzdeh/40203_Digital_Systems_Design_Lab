# Lab 8 - magnitude squared module test
transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vlog ../rtl/shared_arith.v
vlog ../rtl/magnitude_squared_mc.v
vlog ../tb/tb_magnitude_squared_mc.v
vsim -voptargs=+acc work.tb_magnitude_squared_mc
view wave
delete wave *
add wave -r sim:/tb_magnitude_squared_mc/*
WaveRestoreZoom {0 ns} {300 ns}
run -all
