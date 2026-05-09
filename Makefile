# =============================================================================
# SNN プロジェクト用 Makefile (Icarus Verilog)
#
# 使い方:
#   make TOP=barrier        # コンパイル + シミュレーション
#   make TOP=multi_cycle wave   # シミュレーションして GTKWave を起動
#   make list               # 利用可能なターゲット一覧
#   make all                # 全 TB を順次実行
#   make clean              # ビルド成果物を削除
#
# Windows で make が無い場合は scripts/run.ps1 を使ってください:
#   .\scripts\run.ps1 sim barrier
# =============================================================================

TOP           ?= barrier
ROOT          := $(abspath $(CURDIR))
BUILD_DIR     := sim/build
WAVES_DIR     := sim/waves
FILELIST_DIR  := sim/filelists
FILELIST      := $(FILELIST_DIR)/$(TOP).f

VVP_FILE      := $(BUILD_DIR)/$(TOP).vvp
VCD_NAME      := $(TOP)_tb.vcd
VCD_FILE      := $(WAVES_DIR)/$(VCD_NAME)

IVERILOG      ?= iverilog
VVP           ?= vvp
GTKWAVE       ?= gtkwave

.PHONY: sim build wave list all clean help

help:
	@echo "Targets:"
	@echo "  make TOP=<name> sim   - build & run testbench"
	@echo "  make TOP=<name> wave  - run sim and open GTKWave"
	@echo "  make list             - list available TOPs"
	@echo "  make all              - run every testbench"
	@echo "  make clean            - remove build artifacts"

sim: $(VVP_FILE)
	@cd $(BUILD_DIR) && $(VVP) $(TOP).vvp
	@if [ -f $(BUILD_DIR)/$(VCD_NAME) ]; then \
	  mkdir -p $(WAVES_DIR); \
	  mv -f $(BUILD_DIR)/$(VCD_NAME) $(VCD_FILE); \
	  echo "VCD -> $(VCD_FILE)"; \
	fi

build: $(VVP_FILE)

IVERILOG_FLAGS ?= -g2012

$(VVP_FILE): $(FILELIST) | $(BUILD_DIR)
	@cd $(BUILD_DIR) && $(IVERILOG) $(IVERILOG_FLAGS) -o $(TOP).vvp -f $(ROOT)/$(FILELIST)

$(BUILD_DIR) $(WAVES_DIR):
	@mkdir -p $@

wave: sim
	@$(GTKWAVE) $(VCD_FILE) &

list:
	@ls $(FILELIST_DIR)/*.f 2>/dev/null \
	  | xargs -n1 basename \
	  | sed 's/\.f$$//' \
	  | grep -vE '^(common|rtl_all)$$' \
	  | sort

# 全 TB を実行 (1 つでも失敗したら exit 1)
all:
	@fail=0; for f in $(FILELIST_DIR)/*.f; do \
	  base=$$(basename $$f .f); \
	  case $$base in common|rtl_all) continue;; esac; \
	  echo "===== $$base ====="; \
	  $(MAKE) --no-print-directory TOP=$$base sim || fail=1; \
	done; exit $$fail

clean:
	@rm -rf $(BUILD_DIR)/*.vvp $(BUILD_DIR)/*.out $(WAVES_DIR)/*.vcd $(WAVES_DIR)/*.fst
	@echo "cleaned $(BUILD_DIR), $(WAVES_DIR)"
