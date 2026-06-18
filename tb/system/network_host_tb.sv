`timescale 1ns/1ps

module network_host_tb;
  localparam int n_cycles            = 5;
  localparam int cycles_cnt_bitwidth = 4;
  localparam int n_exc_inputs        = 162;
  localparam int n_neurons           = 40;
  localparam time CLK_HALF = 10ns;

  logic clk;
  logic rst_n;
  logic infer_req;
  logic busy;
  logic done;
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
    .cycles_cnt_bitwidth(cycles_cnt_bitwidth)
  ) dut (
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
    .busy(busy),
    .done(done),
    .spikes_out(spikes_out),
    .net_start(net_start),
    .net_sample_ready(net_sample_ready),
    .net_ready(net_ready),
    .net_sample(net_sample),
    .net_in_spikes(net_in_spikes),
    .net_out_spikes(net_out_spikes)
  );

  initial begin
    clk = 1'b0;
    forever #CLK_HALF clk = ~clk;
  end

  initial begin
    rst_n      = 1'b0;
    infer_req  = 1'b0;
    spikes_in  = '0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
  end

endmodule
