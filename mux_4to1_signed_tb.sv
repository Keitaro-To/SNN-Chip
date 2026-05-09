`timescale 1ns / 1ps
module mux_4to1_signed_tb;
  parameter int bitwidth = 8;
  logic [1:0] mux_sel;
  logic signed [bitwidth-1:0] in0, in1, in2, in3, mux_out;

  mux_4to1_signed #(.bitwidth(bitwidth)) dut (.*);

  initial begin
    in0 = 8'd10; in1 = 8'd20; in2 = -8'd30; in3 = 8'd40;
    
    for (int i = 0; i < 4; i++) begin
      mux_sel = i; #10;
      $display("Sel=%d | Out=%d", mux_sel, mux_out);
    end
    $finish;
  end
endmodule