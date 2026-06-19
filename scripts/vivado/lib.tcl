# Shared helpers for Vivado batch flows (XSim / synth / impl).

namespace eval ::snn_vivado {
  variable repo_root ""
  variable filelist_base ""
}

proc ::snn_vivado::init {} {
  variable repo_root
  variable filelist_base

  set script_dir [file dirname [file normalize [info script]]]
  set repo_root [file normalize [file join $script_dir .. ..]]
  set filelist_base [file join $repo_root sim build]

  if {![file isdirectory $repo_root]} {
    error "repo root not found: $repo_root"
  }
}

proc ::snn_vivado::repo_root {} {
  variable repo_root
  if {$repo_root eq ""} {
    ::snn_vivado::init
  }
  return $repo_root
}

proc ::snn_vivado::filelist_base {} {
  variable filelist_base
  if {$filelist_base eq ""} {
    ::snn_vivado::init
  }
  return $filelist_base
}

# Recursively expand sim/filelists/*.f (paths relative to sim/build/).
proc ::snn_vivado::read_filelist_abs {fl_abs} {
  set base [::snn_vivado::filelist_base]
  set fl_abs [file normalize $fl_abs]
  if {![file exists $fl_abs]} {
    error "filelist not found: $fl_abs"
  }

  set fl_dir [file dirname $fl_abs]
  set out {}
  set fh [open $fl_abs r]
  while {[gets $fh line] >= 0} {
    set line [string trim $line]
    if {$line eq ""} { continue }
    if {[string match "#*" $line]} { continue }

    if {[string match "-f *" $line]} {
      set sub [lindex $line 1]
      set sub_abs [file normalize [file join $fl_dir $sub]]
      set out [concat $out [::snn_vivado::read_filelist_abs $sub_abs]]
    } elseif {[string match "-*" $line]} {
      continue
    } else {
      set src [file normalize [file join $base $line]]
      if {![file exists $src]} {
        error "source not found: $src (from $fl_abs)"
      }
      lappend out $src
    }
  }
  close $fh
  return $out
}

proc ::snn_vivado::read_filelist {fl_path} {
  set base [::snn_vivado::filelist_base]
  return [::snn_vivado::read_filelist_abs [file join $base $fl_path]]
}

proc ::snn_vivado::collect_network_uart_sources {} {
  return [::snn_vivado::read_filelist ../filelists/network_uart.f]
}

proc ::snn_vivado::collect_network_uart_tb_sources {} {
  set files [::snn_vivado::collect_network_uart_sources]
  set tb [file normalize [file join [::snn_vivado::repo_root] tb system network_uart_tb.sv]]
  if {![file exists $tb]} {
    error "testbench not found: $tb"
  }
  lappend files $tb
  return $files
}

proc ::snn_vivado::read_rtl {verilog_defines args} {
  set files {}
  if {[llength $args] == 0} {
    set files [::snn_vivado::collect_network_uart_sources]
  } else {
    set files [lindex $args 0]
  }

  set vlog_args [list -sv]
  foreach def $verilog_defines {
    lappend vlog_args -define
    lappend vlog_args $def
  }
  lappend vlog_args $files
  eval read_verilog $vlog_args
}

proc ::snn_vivado::weights_hex {} {
  return [file normalize [file join [::snn_vivado::repo_root] sim mem rom_exc_weights.hex]]
}

proc ::snn_vivado::weights_hex_rtl {} {
  return [file normalize [file join [::snn_vivado::repo_root] rtl mem rom_exc_weights.hex]]
}

proc ::snn_vivado::require_weights {} {
  set sim_hex [::snn_vivado::weights_hex]
  set rtl_hex [::snn_vivado::weights_hex_rtl]
  if {![file exists $sim_hex] || ![file exists $rtl_hex]} {
    error "ROM weights missing. Run: python scripts/weights_to_rom.py --weights rtl/host/data/weights_seed_0.npy"
  }
}

proc ::snn_vivado::part {} {
  return xc7z020clg400-1
}

proc ::snn_vivado::board_part {} {
  return digilentinc.com:zybo-z7-20:part0:1.2
}

proc ::snn_vivado::set_board_part_if_available {} {
  set vivado_root [file normalize [file join [file dirname [info nameofexecutable]] .. ..]]
  set repo_glob [glob -nocomplain [file join $vivado_root data boards boaed_files]]
  if {[llength $repo_glob] > 0} {
    set_property board_part_repo_paths $repo_glob [current_project]
  }
  set bp [::snn_vivado::board_part]
  if {[catch {set_property board_part $bp [current_project]} err]} {
    puts "WARNING: board_part not set ($err); continuing with part only"
  }
}

proc ::snn_vivado::xdc {} {
  return [file normalize [file join [::snn_vivado::repo_root] constraints zybo_z7_20_network_uart.xdc]]
}
