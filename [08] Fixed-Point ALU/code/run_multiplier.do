# Lab 8 - complex multiplier test
transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vlog ../rtl/shared_arith.v
vlog ../rtl/complex_multiplier_mc.v
vlog ../tb/tb_complex_multiplier_mc.v
vsim -voptargs=+acc work.tb_complex_multiplier_mc
view wave
delete wave *
add wave -r sim:/tb_complex_multiplier_mc/*
WaveRestoreZoom {0 ns} {400 ns}
run -all
