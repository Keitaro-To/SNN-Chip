// From vivado_project_prototype/barrier.vhd
module barrier #(
  parameter int N = 8
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         restart,
  input  logic         out_sample,
  input  logic [N-1:0] reg_in,
  output logic         ready,
  output logic [N-1:0] reg_out
);

  logic barrier_rst_n;
  logic barrier_en;

  barrier_cu control_unit (
    .clk(clk),
    .rst_n(rst_n),
    .restart(restart),
    .out_sample(out_sample),
    .barrier_rst_n(barrier_rst_n),
    .barrier_en(barrier_en),
    .ready(ready)
  );

  reg_sync_rst #(.N(N)) datapath (
    .clk(clk),
    .en(barrier_en),
    .rst_n(barrier_rst_n),
    .reg_in(reg_in),
    .reg_out(reg_out)
  );

endmodule

