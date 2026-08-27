# ================================================================
# Experiment 9 - TCAM Timing Constraints
# Functional simulation clock: 100 MHz (10 ns period)
# ================================================================

# Main clock: 100 MHz
create_clock -name clk -period 10.000 -waveform {0.000 5.000} [get_ports {clk}]

# Let TimeQuest calculate device-specific clock uncertainty
derive_clock_uncertainty

# rstN is an asynchronous active-low reset, so it is not timed as
# synchronous data relative to clk.
set_false_path -from [get_ports {rstN}]
