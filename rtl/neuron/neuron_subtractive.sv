// From vivado_project_prototype/neuron_subtractive.vhd
module neuron_subtractive #(
  parameter int neuron_bit_width       = 16,
  parameter int inh_weights_bit_width  = 8,
  parameter int exc_weights_bit_width  = 8,
  parameter int shift                 = 3
) (
  input  logic signed [neuron_bit_width-1:0]      v_th,
  input  logic signed [inh_weights_bit_width-1:0] inh_weight,
  input  logic signed [exc_weights_bit_width-1:0] exc_weight,
  input  logic                                   clk,
  input  logic                                   rst_n,
  input  logic                                   restart,
  input  logic                                   exc,
  input  logic                                   inh,
  input  logic                                   exc_spike,
  input  logic                                   inh_spike,
  output logic                                   neuron_ready,
  output logic                                   out_spike,
  output logic                                   exceed_v_th_out
);

  logic [1:0] update_sel;
  logic       add_or_sub;
  logic       v_en;
  logic       v_rst_n;
  logic       exceed_v_th;

  logic signed [inh_weights_bit_width-1:0] masked_inh_weight;
  logic signed [exc_weights_bit_width-1:0] masked_exc_weight;

  neuron_dp_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) datapath (
    .v_th(v_th),
    .inh_weight(masked_inh_weight),
    .exc_weight(masked_exc_weight),
    .clk(clk),
    .update_sel(update_sel),
    .add_or_sub(add_or_sub),
    .v_en(v_en),
    .v_rst_n(v_rst_n),
    .exceed_v_th(exceed_v_th)
  );

  neuron_cu_subtractive control_unit (
    .clk(clk),
    .rst_n(rst_n),
    .restart(restart),
    .exc(exc),
    .inh(inh),
    .exceed_v_th(exceed_v_th),
    .update_sel(update_sel),
    .add_or_sub(add_or_sub),
    .v_en(v_en),
    .v_rst_n(v_rst_n),
    .neuron_ready(neuron_ready),
    .out_spike(out_spike)
  );

  assign exceed_v_th_out = exceed_v_th;

  and_mask #(.N(exc_weights_bit_width)) exc_mask (
    .input_bits(exc_weight),
    .mask_bit(exc_spike),
    .output_bits(masked_exc_weight)
  );

  and_mask #(.N(inh_weights_bit_width)) inh_mask (
    .input_bits(inh_weight),
    .mask_bit(inh_spike),
    .output_bits(masked_inh_weight)
  );

endmodule

