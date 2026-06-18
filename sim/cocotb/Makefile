# Cocotb simulation for cartpole_host (network_host_tb)
REPO_ROOT := $(abspath ../..)
BUILD_DIR := $(REPO_ROOT)/sim/build

TOPLEVEL_LANG = verilog
SIM ?= icarus
TOPLEVEL = network_host_tb
MODULE = test_cartpole_gym

IVERILOG_ARGS += -g2012

VERILOG_SOURCES += \
	$(REPO_ROOT)/rtl/pkg/spiker_pkg.sv \
	$(REPO_ROOT)/rtl/common/add_sub.sv \
	$(REPO_ROOT)/rtl/common/addr_converter.sv \
	$(REPO_ROOT)/rtl/common/and_mask.sv \
	$(REPO_ROOT)/rtl/common/cmp_eq.sv \
	$(REPO_ROOT)/rtl/common/cmp_gt.sv \
	$(REPO_ROOT)/rtl/common/cnt.sv \
	$(REPO_ROOT)/rtl/common/generic_or.sv \
	$(REPO_ROOT)/rtl/common/mux_4to1_signed.sv \
	$(REPO_ROOT)/rtl/common/mux_8to1.sv \
	$(REPO_ROOT)/rtl/common/mux_16to1.sv \
	$(REPO_ROOT)/rtl/common/reg_sync_rst.sv \
	$(REPO_ROOT)/rtl/common/reg_signed_sync_rst.sv \
	$(REPO_ROOT)/rtl/common/shifter.sv \
	$(REPO_ROOT)/rtl/mem/rom_exc.sv \
	$(REPO_ROOT)/rtl/mem/rom_exc_ip.sv \
	$(REPO_ROOT)/rtl/mem/rom_inh.sv \
	$(REPO_ROOT)/rtl/mem/rom_inh_ip.sv \
	$(REPO_ROOT)/rtl/sync/multi_cycle_datapath.sv \
	$(REPO_ROOT)/rtl/sync/multi_cycle_cu.sv \
	$(REPO_ROOT)/rtl/sync/multi_cycle.sv \
	$(REPO_ROOT)/rtl/sync/barrier_cu.sv \
	$(REPO_ROOT)/rtl/sync/barrier.sv \
	$(REPO_ROOT)/rtl/neuron/neuron_cu_subtractive.sv \
	$(REPO_ROOT)/rtl/neuron/neuron_dp_subtractive.sv \
	$(REPO_ROOT)/rtl/neuron/neuron_subtractive.sv \
	$(REPO_ROOT)/rtl/network/multi_input_cu.sv \
	$(REPO_ROOT)/rtl/network/multi_input_dp.sv \
	$(REPO_ROOT)/rtl/network/multi_input.sv \
	$(REPO_ROOT)/rtl/network/layer.sv \
	$(REPO_ROOT)/rtl/top/network.sv \
	$(REPO_ROOT)/rtl/host/network_infer_ctrl.sv \
	$(REPO_ROOT)/tb/system/network_host_tb.sv

PLUSARGS += +WEIGHTS=$(REPO_ROOT)/sim/mem/rom_exc_weights.hex

export PYTHONPATH := $(REPO_ROOT):$(PYTHONPATH)

include $(shell cocotb-config --makefiles)/Makefile.sim
