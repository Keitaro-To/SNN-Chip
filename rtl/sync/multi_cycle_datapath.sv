// From vivado_project_prototype/multi_cycle_datapath.vhd
module multi_cycle_datapath #(
  parameter int cycles_cnt_bitwidth = 4,
  parameter int n_cycles            = 5
) (
  input  logic clk,
  input  logic cycles_cnt_en,
  input  logic cycles_cnt_rst_n,
  output logic stop
);

  logic [cycles_cnt_bitwidth-1:0] cycles_cnt;

  cnt #(.N(cycles_cnt_bitwidth)) cycles_counter (
    .clk(clk),
    .cnt_en(cycles_cnt_en),
    .cnt_rst_n(cycles_cnt_rst_n),
    .cnt_out(cycles_cnt)
  );

  cmp_eq #(.N(cycles_cnt_bitwidth)) cycles_cmp (
    .in0(cycles_cnt),
    .in1(cycles_cnt_bitwidth'(n_cycles + 1)),
    .cmp_out(stop)
  );

endmodule

