# 1. Setup Libraries and Search Path
set target_library "saed32rvt_tt1p05v25c.db"
set link_library "* $target_library"
set search_path [list . ./RTL_Master ./RTL_Slave ./RTL_Top_Module ]

file mkdir report
file mkdir output 

# 2. Read the File List (filelist.f)
set RTL_FILES [list]
set fp [open "filelist.f" r]

while {[gets $fp line] >= 0} {
    
    set line [string trim $line]
    
   
    if {$line != "" && ![string match "//*" $line] && ![string match "+incdir+*" $line]} {
        lappend RTL_FILES $line
    }
}
close $fp

# 3. Analyze & Elaborate Design
analyze -format sverilog $RTL_FILES
elaborate Top_AHB

# 4. Apply Constraints
source constrain.tcl

# 5. Check Design
check_design

# 6. Compile (Synthesis)
compile_ultra

# 7. Generate Reports
report_timing -delay_type max -max_paths 3 -nworst 10 > report/timing_report.rpt
report_area   > report/area_report.rpt
report_power  > report/power_report.rpt

# 8. Save Gate-Level Netlist
write -format verilog -hierarchy -output output/Top_AHB_netlist.v
write_sdc output/Top_AHB_out.sdc

exit