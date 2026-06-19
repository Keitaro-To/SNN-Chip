# Vivado batch: synth + impl + bitstream for network_uart (Zybo Z7-20).
# Uses an in-memory project so batch builds do not fight GUI-opened .xpr / .runs locks.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lib.tcl]

::snn_vivado::init
::snn_vivado::require_weights

set repo [::snn_vivado::repo_root]
set out_dir [file join $repo fpga build network_uart]
set xdc [::snn_vivado::xdc]

file mkdir $out_dir
cd $out_dir

set files [::snn_vivado::collect_network_uart_sources]

puts "INFO: creating in-memory project (outputs -> $out_dir)"
create_project -in_memory -part [::snn_vivado::part]
set_property target_language Verilog [current_project]

::snn_vivado::read_rtl {} $files

if {![file exists $xdc]} {
  error "constraints not found: $xdc"
}
read_xdc $xdc

set_property top network_uart [current_fileset]
set_property top_lib xil_defaultlib [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: running synthesis for network_uart"
synth_design -top network_uart -part [::snn_vivado::part] -verilog_define SYNTHESIS -flatten_hierarchy rebuilt -directive PerformanceOptimized

report_utilization -file [file join $out_dir network_uart_utilization_synth.rpt]

# Break up high-fanout spike broadcast before placement (timing report: fo~680).
foreach net [get_nets -quiet -hier -filter {NAME =~ *exc_spike*}] {
  set_property MAX_FANOUT 32 $net
}
foreach net [get_nets -quiet -hier -filter {NAME =~ *inh_spike*}] {
  set_property MAX_FANOUT 32 $net
}

puts "INFO: running implementation (timing-driven)"
opt_design -directive Explore
place_design -directive Explore
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
phys_opt_design -directive AggressiveExplore

report_utilization -file [file join $out_dir network_uart_utilization_impl.rpt]
report_timing_summary -file [file join $out_dir network_uart_timing.rpt]

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1]]
puts "INFO: timing WNS = $wns"

write_checkpoint -force [file join $out_dir network_uart_routed.dcp]
write_bitstream -force [file join $out_dir network_uart.bit]

puts "INFO: bitstream written to [file join $out_dir network_uart.bit]"
puts "INFO: open routed design in GUI: open_checkpoint $out_dir/network_uart_routed.dcp"
