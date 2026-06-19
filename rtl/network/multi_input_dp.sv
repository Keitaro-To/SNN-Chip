// From vivado_project_prototype/multi_input_dp_16_exc_8_inh.vhd
module multi_input_dp #(
  parameter int n_exc_inputs     = 16,
  parameter int n_inh_inputs     = 8,
  parameter int exc_cnt_bitwidth = 4,
  parameter int inh_cnt_bitwidth = 3
) (
  input  logic                         clk,
  input  logic [n_exc_inputs-1:0]       exc_spikes,
  input  logic [((n_inh_inputs > 0) ? n_inh_inputs : 1) - 1:0] inh_spikes,
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
  logic [((n_inh_inputs > 0) ? n_inh_inputs : 1) - 1:0] inh_spikes_sampled;
  logic [exc_cnt_bitwidth-1:0]   exc_cnt_sig;
  logic [inh_cnt_bitwidth-1:0]   inh_cnt_sig;

  assign exc_cnt = exc_cnt_sig;
  assign inh_cnt = inh_cnt_sig;

  initial begin
    if (n_exc_inputs > (1 << exc_cnt_bitwidth))
      $fatal(1, "multi_input_dp: n_exc_inputs (%0d) exceeds 2**exc_cnt_bitwidth (%0d).",
             n_exc_inputs, 1 << exc_cnt_bitwidth);
    if (n_inh_inputs > 0 && n_inh_inputs > (1 << inh_cnt_bitwidth))
      $fatal(1, "multi_input_dp: n_inh_inputs (%0d) exceeds 2**inh_cnt_bitwidth (%0d).",
             n_inh_inputs, 1 << inh_cnt_bitwidth);
  end

  generic_or #(.N(n_exc_inputs)) exc_or (
    .or_in(exc_spikes),
    .or_out(exc_yes)
  );

  reg_sync_rst #(.N(n_exc_inputs)) exc_reg (
    .clk(clk),
    .en(exc_sample),
    .rst_n(exc_rst_n),
    .reg_in(exc_spikes),
    .reg_out(exc_spikes_sampled)
  );

  assign exc_spike = exc_spikes_sampled[exc_cnt_sig];

  cnt #(
    .N(exc_cnt_bitwidth),
    .rst_value(n_exc_inputs - 1)
  ) exc_counter (
    .clk(clk),
    .cnt_en(exc_cnt_en),
    .cnt_rst_n(exc_cnt_rst_n),
    .cnt_out(exc_cnt_sig)
  );

  cmp_eq #(.N(exc_cnt_bitwidth)) exc_cmp (
    .in0(exc_cnt_sig),
    .in1(exc_cnt_bitwidth'(n_exc_inputs - 2)),
    .cmp_out(exc_stop)
  );

  generate
    if (n_inh_inputs > 0) begin : gen_inh_path
      generic_or #(.N(n_inh_inputs)) inh_or (
        .or_in(inh_spikes),
        .or_out(inh_yes)
      );

      reg_sync_rst #(.N(n_inh_inputs)) inh_reg (
        .clk(clk),
        .en(inh_sample),
        .rst_n(inh_rst_n),
        .reg_in(inh_spikes),
        .reg_out(inh_spikes_sampled)
      );

      assign inh_spike = inh_spikes_sampled[inh_cnt_sig];

      cnt #(
        .N(inh_cnt_bitwidth),
        .rst_value(n_inh_inputs - 1)
      ) inh_counter (
        .clk(clk),
        .cnt_en(inh_cnt_en),
        .cnt_rst_n(inh_cnt_rst_n),
        .cnt_out(inh_cnt_sig)
      );

      cmp_eq #(.N(inh_cnt_bitwidth)) inh_cmp (
        .in0(inh_cnt_sig),
        .in1(inh_cnt_bitwidth'(n_inh_inputs - 2)),
        .cmp_out(inh_stop)
      );
    end else begin : gen_no_inh
      generic_or #(.N(1)) inh_or (
        .or_in(inh_spikes),
        .or_out(inh_yes)
      );

      reg_sync_rst #(.N(1)) inh_reg (
        .clk(clk),
        .en(inh_sample),
        .rst_n(inh_rst_n),
        .reg_in(inh_spikes),
        .reg_out(inh_spikes_sampled)
      );

      assign inh_spike = inh_spikes_sampled[inh_cnt_sig];

      cnt #(
        .N(inh_cnt_bitwidth),
        .rst_value(0)
      ) inh_counter (
        .clk(clk),
        .cnt_en(inh_cnt_en),
        .cnt_rst_n(inh_cnt_rst_n),
        .cnt_out(inh_cnt_sig)
      );

      cmp_eq #(.N(inh_cnt_bitwidth)) inh_cmp (
        .in0(inh_cnt_sig),
        .in1('0),
        .cmp_out(inh_stop)
      );
    end
  endgenerate

endmodule
