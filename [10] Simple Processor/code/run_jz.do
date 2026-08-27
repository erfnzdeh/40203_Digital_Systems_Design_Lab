# JZ test
transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vlog ../rtl/stack_cpu.v
vlog ../tb/tb_jz_control.v
vsim -voptargs=+acc work.tb_jz_control
run -all
