# 全 RTL を列挙する集約 filelist (system テスト・lint で使用)
-f ../filelists/common.f

# --- common ---
../../rtl/common/add_sub.sv
../../rtl/common/addr_converter.sv
../../rtl/common/and_mask.sv
../../rtl/common/cmp_eq.sv
../../rtl/common/cmp_gt.sv
../../rtl/common/cnt.sv
../../rtl/common/generic_or.sv
../../rtl/common/mux_4to1_signed.sv
../../rtl/common/mux_8to1.sv
../../rtl/common/mux_16to1.sv
../../rtl/common/reg_sync_rst.sv
../../rtl/common/reg_signed_sync_rst.sv
../../rtl/common/shifter.sv

# --- mem ---
../../rtl/mem/rom_exc.sv
../../rtl/mem/rom_exc_ip.sv
../../rtl/mem/rom_inh.sv
../../rtl/mem/rom_inh_ip.sv

# --- sync ---
../../rtl/sync/multi_cycle_datapath.sv
../../rtl/sync/multi_cycle_cu.sv
../../rtl/sync/multi_cycle.sv
../../rtl/sync/barrier_cu.sv
../../rtl/sync/barrier.sv

# --- neuron ---
../../rtl/neuron/neuron_cu_subtractive.sv
../../rtl/neuron/neuron_dp_subtractive.sv
../../rtl/neuron/neuron_subtractive.sv

# --- network ---
../../rtl/network/multi_input_cu.sv
../../rtl/network/multi_input_dp.sv
../../rtl/network/multi_input.sv
../../rtl/network/layer.sv

# --- top ---
../../rtl/top/network.sv
