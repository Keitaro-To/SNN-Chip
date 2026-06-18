`timescale 1ns / 1ps

// subtractive LIF 単体: 膜電位 v と発火を VCD で確認する
module neuron_subtractive_tb;

  localparam int neuron_bit_width       = 16;
  localparam int inh_weights_bit_width  = 8;
  localparam int exc_weights_bit_width  = 8;
  localparam int shift                  = 3;
  localparam time CLK_HALF              = 10ns;

  logic clk, rst_n, restart, exc, inh, exc_spike, inh_spike;
  logic neuron_ready, out_spike, exceed_unused;

  logic signed [neuron_bit_width-1:0]      v_th;
  logic signed [inh_weights_bit_width-1:0] inh_weight;
  logic signed [exc_weights_bit_width-1:0] exc_weight;

  assign v_th       = 16'sd16;
  assign exc_weight = 8'sd8;
  assign inh_weight = -8'sd4;

  neuron_subtractive #(
    .neuron_bit_width(neuron_bit_width),
    .inh_weights_bit_width(inh_weights_bit_width),
    .exc_weights_bit_width(exc_weights_bit_width),
    .shift(shift)
  ) dut (
    .v_th(v_th),
    .inh_weight(inh_weight),
    .exc_weight(exc_weight),
    .clk(clk),
    .rst_n(rst_n),
    .restart(restart),
    .exc(exc),
    .inh(inh),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .neuron_ready(neuron_ready),
    .out_spike(out_spike),
    .exceed_v_th_out(exceed_unused)
  );

  initial clk = 1'b0;
  always #CLK_HALF clk = ~clk;

  task automatic drive(
    input logic r,
    input logic e,
    input logic i,
    input logic es,
    input logic is_
  );
    restart   = r;
    exc       = e;
    inh       = i;
    exc_spike = es;
    inh_spike = is_;
    @(posedge clk);
  endtask

  initial begin
    $dumpfile("neuron_subtractive_tb.vcd");
    $dumpvars(0, neuron_subtractive_tb);

    rst_n = 1'b0;
    restart = 1'b0;
    exc = 1'b0;
    inh = 1'b0;
    exc_spike = 1'b0;
    inh_spike = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    wait (neuron_ready === 1'b1);

    $display("--- restart (v clear) ---");
    drive(1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
    drive(1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

    $display("--- excite only (v += w_exc) ---");
    repeat (4) drive(1'b0, 1'b1, 1'b0, 1'b1, 1'b0);

    $display("--- exc+inh: fire or leak (v=%0d) ---", v_mem);
    repeat (3) drive(1'b0, 1'b1, 1'b1, 1'b1, 1'b1);

    $display("--- inhibit only (v += w_inh) ---");
    repeat (2) drive(1'b0, 1'b0, 1'b1, 1'b0, 1'b1);

    $display("--- idle ---");
    repeat (4) drive(1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

    $display("neuron_subtractive_tb done. final v=%0d out_spike=%b", v_mem, out_spike);
    $finish;
  end

endmodule
