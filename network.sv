// From vivado_project_prototype/network.vhd
module network #(
  parameter int n_cycles            = 5,
  parameter int cycles_cnt_bitwidth = 4
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start,
  input  logic         sample_ready,
  output logic         ready,
  output logic         sample,
  input  logic [15:0]  in_spikes,
  output logic [7:0]   out_spikes
);

  logic start_all;
  logic all_ready;
  logic restart;
  logic layer_0_ready;
  logic [7:0] layer_0_feedback;

  assign sample    = start_all;
  assign all_ready = sample_ready & layer_0_ready;
  assign out_spikes = layer_0_feedback;

  multi_cycle #(
    .cycles_cnt_bitwidth(cycles_cnt_bitwidth),
    .n_cycles(n_cycles)
  ) multi_cycle_control (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .all_ready(all_ready),
    .ready(ready),
    .restart(restart),
    .start_all(start_all)
  );

  layer_8_neurons_16_inputs #(
    .n_exc_inputs(16),
    .n_inh_inputs(8),
    .exc_cnt_bitwidth(4),
    .inh_cnt_bitwidth(3),
    .neuron_bit_width(16),
    .inh_weights_bit_width(8),
    .exc_weights_bit_width(8),
    .shift(3)
  ) layer_0 (
    .clk(clk),
    .rst_n(rst_n),
    .start(start_all),
    .restart(restart),
    .exc_spikes(in_spikes),
    .inh_spikes(layer_0_feedback),
    .ready(layer_0_ready),
    .out_spikes(layer_0_feedback)
  );

endmodule

