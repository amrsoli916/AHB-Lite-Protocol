#creat clock by 100Mhz frequancey
create_clock -period 10      [get_ports HCLK]

#clock uncertainty ->(mergin, jitter & skew)
set_clock_uncertainty 0.2   [get_clocks HCLK]

#set false path for reset & don't optimize for two folps
set_false_path -from        [get_ports HRESET_n]
set_ideal_network           [get_pins syn_reset/sync_resset]
set_dont_touch              [get_cells syn_reset]