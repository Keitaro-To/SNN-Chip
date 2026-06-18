// FPGA top: network + UART host inference bridge.
module network_uart #(
  parameter int CLK_HZ               = 100_000_000,
  parameter int BAUD                 = 115_200,
  parameter int n_cycles             = 5,
  parameter int cycles_cnt_bitwidth  = 4,
  parameter int n_exc_inputs         = 162,
  parameter int n_inh_inputs         = 0,
  parameter int n_neurons            = 40,
  parameter int exc_cnt_bitwidth     = 8,
  parameter int inh_cnt_bitwidth     = 1,
  parameter int neuron_bit_width     = 16,
  parameter int inh_weights_bit_width = 8,
  parameter int exc_weights_bit_width = 8,
  parameter int shift                = 3
) (
  input  logic clk,
  input  logic rst_n,
  input  logic uart_rx,
  output logic uart_tx
);

  logic infer_req;
  logic infer_busy;
  logic infer_done;
  logic [n_exc_inputs-1:0] spikes_in;
  logic [n_neurons-1:0]    spikes_out;

  logic net_start;
  logic net_sample_ready;
  logic net_ready;
  logic net_sample;
  logic [n_exc_inputs-1:0] net_in_spikes;
  logic [n_neurons-1:0]    net_out_spikes;

  network #(
    .n_cycles(n_cycles),
    .cycles_cnt_bitwidth(cycles_cnt_bitwidth),
    .n_exc_inputs(n_exc_inputs),
    .n_inh_inputs(n_inh_inputs),
    .n_neurons(n_neurons),
    .exc_cnt_bitwidth(exc_cnt_bitwidth),
    .inh_cnt_bitwidth(inh_cnt_bitwidth),
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) net_inst (
    .clk(clk),
    .rst_n(rst_n),
    .start(net_start),
    .sample_ready(net_sample_ready),
    .ready(net_ready),
    .sample(net_sample),
    .in_spikes(net_in_spikes),
    .out_spikes(net_out_spikes)
  );

  network_infer_ctrl #(
    .n_exc_inputs(n_exc_inputs),
    .n_neurons(n_neurons),
    .n_cycles(n_cycles)
  ) host_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .infer_req(infer_req),
    .spikes_in(spikes_in),
    .busy(infer_busy),
    .done(infer_done),
    .spikes_out(spikes_out),
    .net_start(net_start),
    .net_sample_ready(net_sample_ready),
    .net_ready(net_ready),
    .net_sample(net_sample),
    .net_in_spikes(net_in_spikes),
    .net_out_spikes(net_out_spikes)
  );

  uart_infer #(
    .CLK_HZ(CLK_HZ),
    .BAUD(BAUD),
    .n_exc_inputs(n_exc_inputs),
    .n_neurons(n_neurons)
  ) uart_host (
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .infer_req(infer_req),
    .spikes_in(spikes_in),
    .infer_busy(infer_busy),
    .infer_done(infer_done),
    .spikes_out(spikes_out)
  );

endmodule
