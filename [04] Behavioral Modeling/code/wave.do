quietly WaveActivateNextPane {} 0
add wave -divider {INPUTS}
add wave sim:/tb_stack/Clk
add wave sim:/tb_stack/RstN
add wave sim:/tb_stack/Push
add wave sim:/tb_stack/Pop
add wave -radix unsigned sim:/tb_stack/Data_In

add wave -divider {OUTPUTS}
add wave -radix unsigned sim:/tb_stack/Data_Out
add wave sim:/tb_stack/Full
add wave sim:/tb_stack/Empty

add wave -divider {INTERNAL}
add wave -radix unsigned sim:/tb_stack/dut/Stack_Pointer
add wave sim:/tb_stack/dut/Stack_Mem

configure wave -namecolwidth 180
configure wave -valuecolwidth 90
configure wave -justifyvalue left
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ns} {300 ns}
