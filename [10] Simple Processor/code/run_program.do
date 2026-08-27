# final program test
transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vlog ../rtl/stack_cpu.v
vlog +incdir+../rtl ../rtl/lab10_system.v
vlog ../tb/tb_lab10_program.v

vsim -voptargs=+acc work.tb_lab10_program
view wave
delete wave *
add wave -divider {input output}
add wave sim:/tb_lab10_program/clk
add wave sim:/tb_lab10_program/reset
add wave -radix unsigned sim:/tb_lab10_program/input_x
add wave -radix hex sim:/tb_lab10_program/digit_high
add wave -radix hex sim:/tb_lab10_program/digit_low
add wave sim:/tb_lab10_program/led_error
add wave sim:/tb_lab10_program/led_done
add wave -divider {cpu}
add wave -radix hex sim:/tb_lab10_program/debug_pc
add wave -radix unsigned sim:/tb_lab10_program/debug_sp
add wave -radix hex sim:/tb_lab10_program/debug_top
add wave -radix hex sim:/tb_lab10_program/debug_second
add wave sim:/tb_lab10_program/debug_s
add wave sim:/tb_lab10_program/debug_z
add wave sim:/tb_lab10_program/debug_instr_done
run -all
