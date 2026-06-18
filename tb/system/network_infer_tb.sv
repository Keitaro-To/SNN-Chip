`timescale 1ns/1ps

// File-based single-inference TB for host/backends/sim_backend.py
module network_infer_tb;
  localparam int n_cycles            = 5;
  localparam int cycles_cnt_bitwidth = 4;
  localparam int n_exc_inputs        = 162;
  localparam int n_neurons           = 40;
  localparam time CLK_HALF = 10ns;
  localparam string IN_FILE  = "../../sim/build/infer_in.hex";
  localparam string OUT_FILE = "../../sim/build/infer_out.hex";

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
    rst_n     = 1'b0;
    infer_req = 1'b0;
    spikes_in = '0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
  end

  int in_fd;
  int out_fd;
  logic [n_exc_inputs-1:0] loaded_spikes;
  int read_count;

  initial begin
    $dumpfile("network_infer_tb.vcd");
    $dumpvars(0, network_infer_tb);

    @(posedge rst_n);
    repeat (4) @(posedge clk);

    in_fd = $fopen(IN_FILE, "r");
    if (in_fd == 0) begin
      $fatal(1, "network_infer_tb: cannot open %s", IN_FILE);
    end
    read_count = $fscanf(in_fd, "%h", loaded_spikes);
    $fclose(in_fd);
    if (read_count != 1) begin
      $fatal(1, "network_infer_tb: failed to read spikes from %s", IN_FILE);
    end

    spikes_in = loaded_spikes;
    infer_req = 1'b1;
    @(posedge clk);
    infer_req = 1'b0;

    wait (done === 1'b1);
    @(posedge clk);

    out_fd = $fopen(OUT_FILE, "w");
    if (out_fd == 0) begin
      $fatal(1, "network_infer_tb: cannot open %s for write", OUT_FILE);
    end
    $fwrite(out_fd, "%0h\n", spikes_out);
    $fclose(out_fd);

    $display("network_infer_tb: out_spikes=%0h", spikes_out);
    $finish;
  end

endmodule
