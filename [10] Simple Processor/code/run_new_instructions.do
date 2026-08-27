# SWAP / SHL / CMP
transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

vlog ../rtl/stack_cpu.v
vlog ../tb/tb_new_instructions.v

vsim -voptargs=+acc work.tb_new_instructions
view wave
delete wave *
add wave -divider {clock reset}
add wave sim:/tb_new_instructions/clk
add wave sim:/tb_new_instructions/reset
add wave -divider {cpu}
add wave -radix hex sim:/tb_new_instructions/debug_pc
add wave -radix unsigned sim:/tb_new_instructions/debug_sp
add wave -radix hex sim:/tb_new_instructions/debug_top
add wave -radix hex sim:/tb_new_instructions/debug_second
add wave sim:/tb_new_instructions/flag_s
add wave sim:/tb_new_instructions/flag_z
add wave sim:/tb_new_instructions/instr_done
add wave -divider {memory}
add wave -radix hex sim:/tb_new_instructions/mem_addr
add wave -radix hex sim:/tb_new_instructions/mem_rdata
add wave -radix hex sim:/tb_new_instructions/mem_wdata
add wave sim:/tb_new_instructions/mem_we
run -all
