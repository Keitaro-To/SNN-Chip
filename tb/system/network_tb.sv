`timescale 1ns/1ps

module network_tb;
  localparam int n_cycles            = 5;
  localparam int cycles_cnt_bitwidth = 4;
  localparam int n_exc_inputs        = 162;
  localparam int n_neurons           = 40;
  localparam time CLK_HALF = 10ns;

  logic        clk;
  logic        rst_n;
  logic        start;
  logic        sample_ready;
  logic        ready;
  logic        sample;
  logic [n_exc_inputs-1:0] in_spikes;
  logic [n_neurons-1:0]    out_spikes;

  network #(
    .n_cycles(n_cycles),
    .cycles_cnt_bitwidth(cycles_cnt_bitwidth)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .sample_ready(sample_ready),
    .ready(ready),
    .sample(sample),
    .in_spikes(in_spikes),
    .out_spikes(out_spikes)
  );

  // Clock
  initial begin
    clk = 1'b0;
    forever #CLK_HALF clk = ~clk;
  end

  // Reset + default inputs
  initial begin
    rst_n        = 1'b0;
    start        = 1'b0;
    sample_ready = 1'b1;  // always ready in this simple TB
    in_spikes    = '0;

    // Reset sequence (active-low)
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
  end

  // Simple stimulus:
  // - wait for DUT ready
  // - pulse start
  // - when sample is asserted, change in_spikes pattern
  initial begin
    // VCD for GTKWave etc.
    $dumpfile("network_tb.vcd");
    $dumpvars(0, network_tb);

    // Wait until reset released
    @(posedge rst_n);

    // Run a few samples (fewer iterations than 8-neuron TB due to longer scans)
    for (int k = 0; k < 5; k++) begin
      // Wait for DUT to be ready to accept a new start
      wait (ready === 1'b1);
      @(posedge clk);
      start = 1'b1;
      @(posedge clk);
      start = 1'b0;

      // Provide some input spikes across the processing window.
      // Update on sample strobes (sample == start_all in DUT)
      repeat (n_cycles + 2) begin
        @(posedge clk);
        if (sample) begin
          // Deterministic but non-trivial pattern
          in_spikes = n_exc_inputs'(1) << (k % n_exc_inputs);
        end
      end
    end

    // Finish
    repeat (10) @(posedge clk);
    $finish;
  end

endmodule
