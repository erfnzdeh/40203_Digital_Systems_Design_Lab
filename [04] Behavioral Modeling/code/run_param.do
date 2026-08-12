transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog stack.v
vlog tb_stack.v

# Second configuration to demonstrate that the design is truly parameterized.
# DEPTH=4, WIDTH=8
vsim -voptargs=+acc -gDEPTH=4 -gWIDTH=8 work.tb_stack

do wave.do
run -all
