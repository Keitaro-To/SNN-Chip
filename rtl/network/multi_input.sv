// From vivado_project_prototype/multi_input_16_exc_8_inh.vhd
module multi_input #(
  parameter int n_exc_inputs     = 16,
  parameter int n_inh_inputs     = 8,
  parameter int exc_cnt_bitwidth = 4,
  parameter int inh_cnt_bitwidth = 3
) (
  input  logic                       clk,
  input  logic                       rst_n,
  input  logic                       restart,
  input  logic                       start,
  input  logic [n_exc_inputs-1:0]     exc_spikes,
  input  logic [((n_inh_inputs > 0) ? n_inh_inputs : 1) - 1:0] inh_spikes,
  input  logic                       neurons_ready,
  output logic [exc_cnt_bitwidth-1:0] exc_cnt,
  output logic [inh_cnt_bitwidth-1:0] inh_cnt,
  output logic                       ready,
  output logic                       neuron_restart,
  output logic                       exc,
  output logic                       inh,
  output logic                       out_sample,
  output logic                       exc_spike,
  output logic                       inh_spike
);

  logic spike_sample;
  logic spike_rst_n;
  logic exc_cnt_en;
  logic exc_cnt_rst_n;
  logic inh_cnt_en;
  logic inh_cnt_rst_n;
  logic exc_yes;
  logic exc_stop;
  logic inh_yes;
  logic inh_stop;

  assign out_sample = spike_sample;

  multi_input_dp #(
    .n_exc_inputs(n_exc_inputs),
    .n_inh_inputs(n_inh_inputs),
    .exc_cnt_bitwidth(exc_cnt_bitwidth),
    .inh_cnt_bitwidth(inh_cnt_bitwidth)
  ) datapath (
    .clk(clk),
    .exc_spikes(exc_spikes),
    .inh_spikes(inh_spikes),
    .exc_sample(spike_sample),
    .exc_rst_n(spike_rst_n),
    .exc_cnt_en(exc_cnt_en),
    .exc_cnt_rst_n(exc_cnt_rst_n),
    .inh_sample(spike_sample),
    .inh_rst_n(spike_rst_n),
    .inh_cnt_en(inh_cnt_en),
    .inh_cnt_rst_n(inh_cnt_rst_n),
    .exc_yes(exc_yes),
    .exc_spike(exc_spike),
    .exc_stop(exc_stop),
    .exc_cnt(exc_cnt),
    .inh_yes(inh_yes),
    .inh_spike(inh_spike),
    .inh_stop(inh_stop),
    .inh_cnt(inh_cnt)
  );

  multi_input_cu control_unit (
    .clk(clk),
    .rst_n(rst_n),
    .restart(restart),
    .start(start),
    .neurons_ready(neurons_ready),
    .exc_yes(exc_yes),
    .exc_stop(exc_stop),
    .inh_yes(inh_yes),
    .inh_stop(inh_stop),
    .exc_cnt_en(exc_cnt_en),
    .exc_cnt_rst_n(exc_cnt_rst_n),
    .inh_cnt_en(inh_cnt_en),
    .inh_cnt_rst_n(inh_cnt_rst_n),
    .exc(exc),
    .inh(inh),
    .spike_sample(spike_sample),
    .spike_rst_n(spike_rst_n),
    .neuron_restart(neuron_restart),
    .ready(ready)
  );

endmodule
