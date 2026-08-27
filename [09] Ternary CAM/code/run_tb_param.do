vlog TCAM.v TB_param.v
vsim work.TB_param
add wave -r sim:/TB_param/*
add wave -r sim:/TB_param/dut/*
run -all
wave zoom full
