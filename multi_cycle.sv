// From vivado_project_prototype/multi_cycle.vhd
module multi_cycle #(
  parameter int cycles_cnt_bitwidth = 4,
  parameter int n_cycles            = 5
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic all_ready,
  output logic ready,
  output logic restart,
  output logic start_all
);

  logic cycles_cnt_en;
  logic cycles_cnt_rst_n;
  logic stop;

  multi_cycle_dapapath #(
    .cycles_cnt_bitwidth(cycles_cnt_bitwidth),
    .n_cycles(n_cycles)
  ) datapath (
    .clk(clk),
    .cycles_cnt_en(cycles_cnt_en),
    .cycles_cnt_rst_n(cycles_cnt_rst_n),
    .stop(stop)
  );

  multi_cycle_cu control_unit (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .all_ready(all_ready),
    .stop(stop),
    .cycles_cnt_en(cycles_cnt_en),
    .cycles_cnt_rst_n(cycles_cnt_rst_n),
    .ready(ready),
    .restart(restart),
    .start_all(start_all)
  );

endmodule

