# Common files needed by every testbench.
# NOTE: iverilog command files use '#' for comments (NOT '//').
# Paths are relative to the directory iverilog is invoked from
# (run.ps1 / Makefile invoke iverilog with CWD = sim/build/).
# Compile-language options like '-g2012' are passed on the command
# line by the runner script, not from this file.

# --- Package (must be compiled first) ---
../../rtl/pkg/spiker_pkg.sv
