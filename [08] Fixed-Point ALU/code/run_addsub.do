# Lab 8 - add/sub module test
transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vlog ../rtl/shared_arith.v
vlog ../rtl/complex_addsub_mc.v
vlog ../tb/tb_complex_addsub_mc.v
vsim -voptargs=+acc work.tb_complex_addsub_mc
view wave
delete wave *
add wave -r sim:/tb_complex_addsub_mc/*
WaveRestoreZoom {0 ns} {300 ns}
run -all
