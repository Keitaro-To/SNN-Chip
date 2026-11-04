# neuron_array の消費電力 (段階 3: 配線なし STA、VCD なし・活動率は仮定)。
# 実行: ..\run_sta.ps1 sta_power.tcl sta_power.log
# 活動率の仮定: 入力スパイク線 s_in は 1 ステップに 10% がトグル、設定系と v_th・漏れシフト量 k は静止 (LIF 版)。
# 内部ネットの活動率は OpenSTA が入力から論理を通して伝搬させて推定する。
read_liberty ../lib/NangateOpenCellLibrary_typical.lib
proc strip_signed {in out} {
    set f [open $in r]; set d [read $f]; close $f
    regsub -all { signed } $d { } d
    set f [open $out w]; puts -nonewline $f $d; close $f
}
strip_signed neuron_array_netlist.v neuron_array_netlist_sta.v
read_verilog neuron_array_netlist_sta.v
link_design neuron_array

set_driving_cell -lib_cell BUF_X1 [delete_from_list [all_inputs] [get_ports clk]]
set_load 0.003898 [all_outputs]

foreach {label period} {"48 kHz (1 ステップ = 20.8 us)" 20833.3 "1 MHz (1 us)" 1000.0 "500 MHz" 2.0} {
    puts ""
    puts "================ クロック $label ================"
    create_clock -name clk -period $period [get_ports clk]
    # 活動率: -activity = 1 クロックあたりのトグル回数、-duty = 1 である確率 (クロック定義後に設定する)
    set_power_activity -input -activity 0.1 -duty 0.05
    set_power_activity -input_ports [get_ports {cfg_we cfg_addr[*] cfg_data[*] v_th[*] k[*]}] -activity 0 -duty 0
    set_power_activity -input_ports [get_ports rst_n] -activity 0 -duty 1
    report_power -digits 6
}
puts ""
puts "================ 活動率の注釈状況 ================"
report_activity_annotation
