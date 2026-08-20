# Lab 8 - final ALU test
transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vlog ../rtl/shared_arith.v
vlog ../rtl/complex_alu_mc.v
vlog ../tb/tb_complex_alu_mc.v

vsim -voptargs=+acc work.tb_complex_alu_mc
view wave
delete wave *
add wave -r sim:/tb_complex_alu_mc/dut/*
WaveRestoreZoom {0 ns} {650 ns}
run -all
