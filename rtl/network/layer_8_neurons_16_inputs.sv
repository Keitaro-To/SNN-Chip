// From vivado_project_prototype/layer_8_neurons_16_inputs.vhd
module layer_8_neurons_16_inputs #(
  parameter int n_exc_inputs          = 16,
  parameter int n_inh_inputs          = 8,
  parameter int exc_cnt_bitwidth      = 4,
  parameter int inh_cnt_bitwidth      = 3,
  parameter int neuron_bit_width      = 16,
  parameter int inh_weights_bit_width = 8,
  parameter int exc_weights_bit_width = 8,
  parameter int shift                 = 3
) (
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     start,
  input  logic                     restart,
  input  logic [n_exc_inputs-1:0]   exc_spikes,
  input  logic [n_inh_inputs-1:0]   inh_spikes,
  output logic                     ready,
  output logic [7:0]               out_spikes
);

  // Constants (thresholds)
  localparam logic signed [neuron_bit_width-1:0] v_th_0 = 16'b0000_0000_0001_0000;
  localparam logic signed [neuron_bit_width-1:0] v_th_1 = 16'b0000_0000_0001_0000;
  localparam logic signed [neuron_bit_width-1:0] v_th_2 = 16'b0000_0000_0001_0000;
  localparam logic signed [neuron_bit_width-1:0] v_th_3 = 16'b0000_0000_0001_0000;
  localparam logic signed [neuron_bit_width-1:0] v_th_4 = 16'b0000_0000_0001_0000;
  localparam logic signed [neuron_bit_width-1:0] v_th_5 = 16'b0000_0000_0001_0000;
  localparam logic signed [neuron_bit_width-1:0] v_th_6 = 16'b0000_0000_0001_0000;
  localparam logic signed [neuron_bit_width-1:0] v_th_7 = 16'b0000_0000_0001_0000;

  logic neurons_ready;
  logic exc;
  logic inh;
  logic exc_spike;
  logic inh_spike;
  logic [exc_cnt_bitwidth-1:0] exc_cnt;
  logic [inh_cnt_bitwidth-1:0] inh_cnt;
  logic [exc_cnt_bitwidth-1:0] exc_addr;
  logic [inh_cnt_bitwidth-1:0] inh_addr;
  logic neuron_restart;
  logic barrier_ready;
  logic [7:0] out_spikes_inst;
  logic out_sample;

  logic neuron_ready_0, neuron_ready_1, neuron_ready_2, neuron_ready_3;
  logic neuron_ready_4, neuron_ready_5, neuron_ready_6, neuron_ready_7;

  logic [inh_weights_bit_width-1:0] inh_weight_0, inh_weight_1, inh_weight_2, inh_weight_3;
  logic [inh_weights_bit_width-1:0] inh_weight_4, inh_weight_5, inh_weight_6, inh_weight_7;
  logic [exc_weights_bit_width-1:0] exc_weight_0, exc_weight_1, exc_weight_2, exc_weight_3;
  logic [exc_weights_bit_width-1:0] exc_weight_4, exc_weight_5, exc_weight_6, exc_weight_7;

  assign neurons_ready =
    neuron_ready_0 & neuron_ready_1 & neuron_ready_2 & neuron_ready_3 &
    neuron_ready_4 & neuron_ready_5 & neuron_ready_6 & neuron_ready_7 &
    barrier_ready;

  multi_input_16_exc_8_inh #(
    .n_exc_inputs(n_exc_inputs),
    .n_inh_inputs(n_inh_inputs),
    .exc_cnt_bitwidth(exc_cnt_bitwidth),
    .inh_cnt_bitwidth(inh_cnt_bitwidth)
  ) multi_input_control (
    .clk(clk),
    .rst_n(rst_n),
    .restart(restart),
    .start(start),
    .exc_spikes(exc_spikes),
    .inh_spikes(inh_spikes),
    .neurons_ready(neurons_ready),
    .exc_cnt(exc_cnt),
    .inh_cnt(inh_cnt),
    .ready(ready),
    .neuron_restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .out_sample(out_sample),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike)
  );

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) neuron_0 (
    .v_th(v_th_0),
    .inh_weight($signed(inh_weight_0)),
    .exc_weight($signed(exc_weight_0)),
    .clk(clk),
    .rst_n(rst_n),
    .restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready_0),
    .out_spike(out_spikes_inst[0])
  );

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) neuron_1 (
    .v_th(v_th_1),
    .inh_weight($signed(inh_weight_1)),
    .exc_weight($signed(exc_weight_1)),
    .clk(clk),
    .rst_n(rst_n),
    .restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready_1),
    .out_spike(out_spikes_inst[1])
  );

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) neuron_2 (
    .v_th(v_th_2),
    .inh_weight($signed(inh_weight_2)),
    .exc_weight($signed(exc_weight_2)),
    .clk(clk),
    .rst_n(rst_n),
    .restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready_2),
    .out_spike(out_spikes_inst[2])
  );

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) neuron_3 (
    .v_th(v_th_3),
    .inh_weight($signed(inh_weight_3)),
    .exc_weight($signed(exc_weight_3)),
    .clk(clk),
    .rst_n(rst_n),
    .restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready_3),
    .out_spike(out_spikes_inst[3])
  );

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) neuron_4 (
    .v_th(v_th_4),
    .inh_weight($signed(inh_weight_4)),
    .exc_weight($signed(exc_weight_4)),
    .clk(clk),
    .rst_n(rst_n),
    .restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready_4),
    .out_spike(out_spikes_inst[4])
  );

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) neuron_5 (
    .v_th(v_th_5),
    .inh_weight($signed(inh_weight_5)),
    .exc_weight($signed(exc_weight_5)),
    .clk(clk),
    .rst_n(rst_n),
    .restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready_5),
    .out_spike(out_spikes_inst[5])
  );

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) neuron_6 (
    .v_th(v_th_6),
    .inh_weight($signed(inh_weight_6)),
    .exc_weight($signed(exc_weight_6)),
    .clk(clk),
    .rst_n(rst_n),
    .restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready_6),
    .out_spike(out_spikes_inst[6])
  );

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) neuron_7 (
    .v_th(v_th_7),
    .inh_weight($signed(inh_weight_7)),
    .exc_weight($signed(exc_weight_7)),
    .clk(clk),
    .rst_n(rst_n),
    .restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready_7),
    .out_spike(out_spikes_inst[7])
  );

  rom_16x8_exclif1 exc_mem (
    .clka(clk),
    .addra(exc_addr),
    .dout_0(exc_weight_0),
    .dout_1(exc_weight_1),
    .dout_2(exc_weight_2),
    .dout_3(exc_weight_3),
    .dout_4(exc_weight_4),
    .dout_5(exc_weight_5),
    .dout_6(exc_weight_6),
    .dout_7(exc_weight_7)
  );

  addr_converter #(.N(exc_cnt_bitwidth)) exc_addr_conv (
    .addr_in(exc_cnt),
    .addr_out(exc_addr)
  );

  rom_8x8_inhlif1 inh_mem (
    .clka(clk),
    .addra(inh_addr),
    .dout_0(inh_weight_0),
    .dout_1(inh_weight_1),
    .dout_2(inh_weight_2),
    .dout_3(inh_weight_3),
    .dout_4(inh_weight_4),
    .dout_5(inh_weight_5),
    .dout_6(inh_weight_6),
    .dout_7(inh_weight_7)
  );

  addr_converter #(.N(inh_cnt_bitwidth)) inh_addr_conv (
    .addr_in(inh_cnt),
    .addr_out(inh_addr)
  );

  barrier #(.N(8)) spikes_barrier (
    .clk(clk),
    .rst_n(rst_n),
    .restart(restart),
    .out_sample(out_sample),
    .reg_in(out_spikes_inst),
    .ready(barrier_ready),
    .reg_out(out_spikes)
  );

endmodule

