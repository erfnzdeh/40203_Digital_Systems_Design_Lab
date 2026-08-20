# Lab 8 timing constraint
# 50 MHz clock => 20 ns period
create_clock -name clk -period 20.000 [get_ports {clk}]
derive_clock_uncertainty
