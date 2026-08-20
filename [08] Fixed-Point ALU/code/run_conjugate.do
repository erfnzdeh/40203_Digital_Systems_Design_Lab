# Lab 8 - conjugate module test
transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vlog ../rtl/shared_arith.v
vlog ../rtl/complex_conjugate.v
vlog ../tb/tb_complex_conjugate.v
vsim -voptargs=+acc work.tb_complex_conjugate
view wave
delete wave *
add wave -r sim:/tb_complex_conjugate/*
WaveRestoreZoom {0 ns} {220 ns}
run -all
