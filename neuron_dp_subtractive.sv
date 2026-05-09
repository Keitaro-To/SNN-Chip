// From vivado_project_prototype/neuron_dp_subtractive.vhd
module neuron_dp_subtractive #(
  parameter int neuron_bit_width       = 16,
  parameter int inh_weights_bit_width  = 8,
  parameter int exc_weights_bit_width  = 8,
  parameter int shift                 = 3
) (
  input  logic signed [neuron_bit_width-1:0]      v_th,
  input  logic signed [inh_weights_bit_width-1:0] inh_weight,
  input  logic signed [exc_weights_bit_width-1:0] exc_weight,
  input  logic                                   clk,
  input  logic [1:0]                             update_sel,
  input  logic                                   add_or_sub,
  input  logic                                   v_en,
  input  logic                                   v_rst_n,
  output logic                                   exceed_v_th
);

  logic signed [neuron_bit_width-1:0] update;
  logic signed [neuron_bit_width-1:0] v_value;
  logic signed [neuron_bit_width-1:0] v;
  logic signed [neuron_bit_width-1:0] v_shifted;
  logic signed [neuron_bit_width-1:0] in2_signal;
  logic signed [neuron_bit_width-1:0] in3_signal;

  // Sign-extend weights up to neuron_bit_width
  assign in2_signal = {{(neuron_bit_width-exc_weights_bit_width){exc_weight[exc_weights_bit_width-1]}}, exc_weight};
  assign in3_signal = {{(neuron_bit_width-inh_weights_bit_width){inh_weight[inh_weights_bit_width-1]}}, inh_weight};

  shifter #(.N(neuron_bit_width), .shift(shift)) v_shifter (
    .shifter_in(v),
    .shifted_out(v_shifted)
  );

  mux_4to1_signed #(.bitwidth(neuron_bit_width)) update_mux (
    .mux_sel(update_sel),
    .in0(v_th),
    .in1(v_shifted),
    .in2(in2_signal),
    .in3(in3_signal),
    .mux_out(update)
  );

  add_sub #(.N(neuron_bit_width)) update_add_sub (
    .in0(v),
    .in1(update),
    .add_or_sub(add_or_sub),
    .add_sub_out(v_value)
  );

  reg_signed_sync_rst #(.N(neuron_bit_width)) v_reg (
    .clk(clk),
    .en(v_en),
    .rst_n(v_rst_n),
    .reg_in(v_value),
    .reg_out(v)
  );

  cmp_gt #(.N(neuron_bit_width)) fire_cmp (
    .in0(v),
    .in1(v_th),
    .cmp_out(exceed_v_th)
  );

endmodule

