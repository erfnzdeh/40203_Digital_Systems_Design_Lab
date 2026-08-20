transcript on

if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog UARTSender.v UARTReceiver.v UARTTop.v Tester.v
vsim work.Tester

view wave
add wave -divider "TOP LOOPBACK"
add wave sim:/Tester/clk
add wave sim:/Tester/rstN
add wave sim:/Tester/new_data
add wave -radix binary sim:/Tester/send_data
add wave sim:/Tester/tx
add wave sim:/Tester/busy
add wave -radix binary sim:/Tester/rec_data
add wave sim:/Tester/rec_new_data
add wave sim:/Tester/correct_data

add wave -divider "FAULT TEST RECEIVER"
add wave sim:/Tester/fault_rx
add wave -radix binary sim:/Tester/fault_data
add wave sim:/Tester/fault_new_data
add wave sim:/Tester/fault_correct

run -all
wave zoom full
