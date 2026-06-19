# Vivado XSim: network_uart_tb UART loopback smoke test.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir lib.tcl]

::snn_vivado::init
::snn_vivado::require_weights

set repo [::snn_vivado::repo_root]
set proj_dir [file join $repo fpga build network_uart_xsim]
set weights [::snn_vivado::weights_hex]

file mkdir $proj_dir
cd $proj_dir

set files [::snn_vivado::collect_network_uart_tb_sources]

create_project network_uart_xsim $proj_dir -part [::snn_vivado::part] -force
::snn_vivado::set_board_part_if_available
set_property target_language Verilog [current_project]

::snn_vivado::read_rtl {} $files

set_property top network_uart_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set_property -name {xsim.simulate.runtime} -value {20ms} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]
set weights_arg "WEIGHTS=$weights"
set_property -name {xsim.simulate.xsim.more_options} -value [list -testplusarg $weights_arg] -objects [get_filesets sim_1]

update_compile_order -fileset sources_1

puts "INFO: launching XSim for network_uart_tb (weights=$weights)"
launch_simulation -simset sim_1
run 20ms

if {[catch {close_sim}]} {
  puts "INFO: close_sim: $::errorInfo"
}

puts "INFO: XSim smoke test finished"
