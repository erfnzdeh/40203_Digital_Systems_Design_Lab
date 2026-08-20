# Lab 8 - final processor simulation
# Run this file from the modelsim folder with: do run_all.do

transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

# compile RTL
vlog ../rtl/shared_arith.v
vlog ../rtl/complex_addsub_mc.v
vlog ../rtl/complex_multiplier_mc.v
vlog ../rtl/complex_conjugate.v
vlog ../rtl/magnitude_squared_mc.v
vlog ../rtl/complex_alu_mc.v
vlog ../rtl/instruction_memory.v
vlog ../rtl/complex_processor.v

# compile testbench
vlog ../tb/tb_complex_processor.v

vsim -voptargs=+acc work.tb_complex_processor
view wave
delete wave *

# main input/control signals
add wave -divider {TOP CONTROL}
add wave sim:/tb_complex_processor/clk
add wave sim:/tb_complex_processor/reset
add wave sim:/tb_complex_processor/start
add wave sim:/tb_complex_processor/busy
add wave sim:/tb_complex_processor/done

# results and flags
add wave -divider {RESULT AND FLAGS}
add wave -radix unsigned  sim:/tb_complex_processor/result_pc
add wave -radix decimal   sim:/tb_complex_processor/rr
add wave -radix decimal   sim:/tb_complex_processor/ri
add wave sim:/tb_complex_processor/valid
add wave sim:/tb_complex_processor/overflow
add wave sim:/tb_complex_processor/zero
add wave sim:/tb_complex_processor/real_negative
add wave sim:/tb_complex_processor/imag_negative

# processor controller
add wave -divider {PROCESSOR FSM}
add wave -radix unsigned sim:/tb_complex_processor/dut/pc
add wave sim:/tb_complex_processor/dut/state
add wave sim:/tb_complex_processor/dut/opcode_reg

# ALU states and the shared resources
add wave -divider {ALU FSM AND SHARED UNITS}
add wave sim:/tb_complex_processor/dut/ALU/state
add wave sim:/tb_complex_processor/dut/ALU/busy
add wave sim:/tb_complex_processor/dut/ALU/valid
add wave -radix decimal sim:/tb_complex_processor/dut/ALU/mul_a
add wave -radix decimal sim:/tb_complex_processor/dut/ALU/mul_b
add wave -radix decimal sim:/tb_complex_processor/dut/ALU/mul_y
add wave -radix decimal sim:/tb_complex_processor/dut/ALU/add_a
add wave -radix decimal sim:/tb_complex_processor/dut/ALU/add_b
add wave sim:/tb_complex_processor/dut/ALU/add_sub
add wave -radix decimal sim:/tb_complex_processor/dut/ALU/add_y

# set the useful time range before running, so the final wave is not zoomed on 1 ns
WaveRestoreZoom {0 ns} {850 ns}
run -all
