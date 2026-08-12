transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work
vlog ../src/incubator.v
vlog incubator_tb.v
vsim -voptargs=+acc work.incubator_tb
do wave.do
run -all
wave zoom full
