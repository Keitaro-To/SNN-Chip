# neuron_array 全体のタイミング STA (reports の値は NT=8, T=8 = 64 ニューロン)。
# 実行: ..\run_sta.ps1 sta_timing.tcl
# ABC はモジュールごとに独立に遅延を出すが、ここでは階層をまたいだ経路
# (s_out FF → tile の any → wta_rail → inh → 膜電位 FF) を通して評価する。
read_liberty ../lib/NangateOpenCellLibrary_typical.lib
# OpenSTA の Verilog リーダは "signed" 修飾子を受け付けないので、取り除いたコピーを読む
proc strip_signed {in out} {
    set f [open $in r]; set d [read $f]; close $f
    regsub -all { signed } $d { } d
    set f [open $out w]; puts -nonewline $f $d; close $f
}
strip_signed neuron_array_netlist.v neuron_array_netlist_sta.v
read_verilog neuron_array_netlist_sta.v
link_design neuron_array

create_clock -name clk -period 2.0 [get_ports clk]
set_input_delay  0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]
set_output_delay 0 -clock clk [all_outputs]
set_driving_cell -lib_cell BUF_X1 [delete_from_list [all_inputs] [get_ports clk]]
set_load 0.003898 [all_outputs]

puts "================ 最長パス (setup) ================"
report_checks -path_delay max -fields {slew cap fanout} -digits 3
puts "================ 上位 5 経路 ================"
report_checks -path_delay max -group_path_count 5 -endpoint_path_count 1 -format summary
puts "================ サマリ ================"
report_wns
report_tns

# ---- 2 回目: 設定系を除外して「動作中」の経路を見る ----
# cfg_* は 1 本の入力が全ニューロンの重み FF (800 個超) に直結していて、BUF_X1 駆動では
# その配線容量だけで 1.9 ns かかる。重み書き込みは動作中には行わず速度も要らないので false path にする。
# v_th と漏れシフト量 k も全ニューロンに配る定数扱いの入力なので同様に除外する (LIF 版: k を追加)。
puts ""
puts "================ 設定系 (cfg_*, v_th, k) を除外した最長パス ================"
set_false_path -from [get_ports {cfg_we cfg_addr[*] cfg_data[*] v_th[*] k[*] rst_n}]
report_checks -path_delay max -fields {slew cap fanout} -digits 3
puts "================ 上位 5 経路 (設定系除外) ================"
report_checks -path_delay max -group_path_count 5 -endpoint_path_count 1 -format summary
report_wns
report_tns

# ---- WTA レール (u_rail) を通る経路だけを抜き出す ----
puts ""
puts "================ wta_rail を通る最長パス ================"
if {[catch {report_checks -path_delay max -through [get_pins -hierarchical u_rail/*] -fields {fanout cap} -digits 3} msg]} {
    puts "u_rail 経路の抽出に失敗: $msg"
}
