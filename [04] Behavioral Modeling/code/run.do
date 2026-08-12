transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog stack.v
vlog tb_stack.v

vsim -voptargs=+acc work.tb_stack

do wave.do
run -all
