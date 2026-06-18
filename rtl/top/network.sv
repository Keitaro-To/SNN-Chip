// From vivado_project_prototype/network.vhd
module network #(
  parameter int n_cycles            = 5,
  parameter int cycles_cnt_bitwidth = 4,
  parameter int n_exc_inputs           = 162,
  parameter int n_inh_inputs           = 0,
  parameter int n_neurons              = 40,
  parameter int exc_cnt_bitwidth       = 8,
  parameter int inh_cnt_bitwidth       = 1,
  parameter int neuron_bit_width       = 16,
  parameter int inh_weights_bit_width  = 8,
  parameter int exc_weights_bit_width  = 8,
  parameter int shift                  = 3
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start,
  input  logic         sample_ready,
  output logic         ready,
  output logic         sample,
  input  logic [n_exc_inputs-1:0]  in_spikes,
  output logic [n_neurons-1:0]     out_spikes
);

  logic start_all;
  logic all_ready;
  logic restart;
  logic layer_ready;
  logic [n_neurons-1:0] layer_feedback;
  logic [((n_inh_inputs > 0) ? n_inh_inputs : 1) - 1:0] inh_spikes_to_layer;

  initial begin
    if (n_inh_inputs > 0 && n_inh_inputs != n_neurons)
      $fatal(1, "network: n_inh_inputs (%0d) must equal n_neurons (%0d) for feedback wiring.",
             n_inh_inputs, n_neurons);
  end

  assign sample     = start_all;
  assign all_ready  = sample_ready & layer_ready;
  assign out_spikes = layer_feedback;

  generate
    if (n_inh_inputs > 0) begin : gen_inh_feedback
      assign inh_spikes_to_layer = layer_feedback[n_inh_inputs-1:0];
    end else begin : gen_no_inh_feedback
      assign inh_spikes_to_layer = 1'b0;
    end
  endgenerate

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

  layer #(
    .n_exc_inputs(n_exc_inputs),
    .n_inh_inputs(n_inh_inputs),
    .n_neurons(n_neurons),
    .exc_cnt_bitwidth(exc_cnt_bitwidth),
    .inh_cnt_bitwidth(inh_cnt_bitwidth),
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) layer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .start(start_all),
    .restart(restart),
    .exc_spikes(in_spikes),
    .inh_spikes(inh_spikes_to_layer),
    .ready(layer_ready),
    .out_spikes(layer_feedback)
  );

endmodule
