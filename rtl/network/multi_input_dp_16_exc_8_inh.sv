// From vivado_project_prototype/multi_input_dp_16_exc_8_inh.vhd
module multi_input_dp_16_exc_8_inh #(
  parameter int n_exc_inputs     = 16,
  parameter int n_inh_inputs     = 8,
  parameter int exc_cnt_bitwidth = 4,
  parameter int inh_cnt_bitwidth = 3
) (
  input  logic                         clk,
  input  logic [n_exc_inputs-1:0]       exc_spikes,
  input  logic [n_inh_inputs-1:0]       inh_spikes,
  input  logic                         exc_sample,
  input  logic                         exc_rst_n,
  input  logic                         exc_cnt_en,
  input  logic                         exc_cnt_rst_n,
  input  logic                         inh_sample,
  input  logic                         inh_rst_n,
  input  logic                         inh_cnt_en,
  input  logic                         inh_cnt_rst_n,
  output logic                         exc_yes,
  output logic                         exc_spike,
  output logic                         exc_stop,
  output logic [exc_cnt_bitwidth-1:0]   exc_cnt,
  output logic                         inh_yes,
  output logic                         inh_spike,
  output logic                         inh_stop,
  output logic [inh_cnt_bitwidth-1:0]   inh_cnt
);

  logic [n_exc_inputs-1:0]       exc_spikes_sampled;
  logic [n_inh_inputs-1:0]       inh_spikes_sampled;
  logic [exc_cnt_bitwidth-1:0]   exc_cnt_sig;
  logic [inh_cnt_bitwidth-1:0]   inh_cnt_sig;

  assign exc_cnt = exc_cnt_sig;
  assign inh_cnt = inh_cnt_sig;

  generic_or #(.N(n_exc_inputs)) exc_or (
    .or_in(exc_spikes),
    .or_out(exc_yes)
  );

  generic_or #(.N(n_inh_inputs)) inh_or (
    .or_in(inh_spikes),
    .or_out(inh_yes)
  );

  reg_sync_rst #(.N(n_exc_inputs)) exc_reg (
    .clk(clk),
    .en(exc_sample),
    .rst_n(exc_rst_n),
    .reg_in(exc_spikes),
    .reg_out(exc_spikes_sampled)
  );

  reg_sync_rst #(.N(n_inh_inputs)) inh_reg (
    .clk(clk),
    .en(inh_sample),
    .rst_n(inh_rst_n),
    .reg_in(inh_spikes),
    .reg_out(inh_spikes_sampled)
  );

  // Select current spike bit based on counter
  mux_16to1 exc_mux (
    .mux_sel(exc_cnt_sig),
    .in0(exc_spikes_sampled[0]),
    .in1(exc_spikes_sampled[1]),
    .in2(exc_spikes_sampled[2]),
    .in3(exc_spikes_sampled[3]),
    .in4(exc_spikes_sampled[4]),
    .in5(exc_spikes_sampled[5]),
    .in6(exc_spikes_sampled[6]),
    .in7(exc_spikes_sampled[7]),
    .in8(exc_spikes_sampled[8]),
    .in9(exc_spikes_sampled[9]),
    .in10(exc_spikes_sampled[10]),
    .in11(exc_spikes_sampled[11]),
    .in12(exc_spikes_sampled[12]),
    .in13(exc_spikes_sampled[13]),
    .in14(exc_spikes_sampled[14]),
    .in15(exc_spikes_sampled[15]),
    .mux_out(exc_spike)
  );

  mux_8to1 inh_mux (
    .mux_sel(inh_cnt_sig),
    .in0(inh_spikes_sampled[0]),
    .in1(inh_spikes_sampled[1]),
    .in2(inh_spikes_sampled[2]),
    .in3(inh_spikes_sampled[3]),
    .in4(inh_spikes_sampled[4]),
    .in5(inh_spikes_sampled[5]),
    .in6(inh_spikes_sampled[6]),
    .in7(inh_spikes_sampled[7]),
    .mux_out(inh_spike)
  );

  // Counters: match VHDL rst_value 15/7
  cnt #(.N(exc_cnt_bitwidth), .rst_value(15)) exc_counter (
    .clk(clk),
    .cnt_en(exc_cnt_en),
    .cnt_rst_n(exc_cnt_rst_n),
    .cnt_out(exc_cnt_sig)
  );

  cnt #(.N(inh_cnt_bitwidth), .rst_value(7)) inh_counter (
    .clk(clk),
    .cnt_en(inh_cnt_en),
    .cnt_rst_n(inh_cnt_rst_n),
    .cnt_out(inh_cnt_sig)
  );

  // Stop when counter reaches (n_inputs - 2)
  cmp_eq #(.N(exc_cnt_bitwidth)) exc_cmp (
    .in0(exc_cnt_sig),
    .in1(exc_cnt_bitwidth'(n_exc_inputs - 2)),
    .cmp_out(exc_stop)
  );

  cmp_eq #(.N(inh_cnt_bitwidth)) inh_cmp (
    .in0(inh_cnt_sig),
    .in1(inh_cnt_bitwidth'(n_inh_inputs - 2)),
    .cmp_out(inh_stop)
  );

endmodule

