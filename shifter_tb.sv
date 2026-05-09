`timescale 1ns / 1ps

module shifter_tb;

  parameter int N = 8;
  parameter int shift = 2; // 2ビット右シフト (1/4にする)
  
  logic signed [N-1:0] shifter_in;
  logic signed [N-1:0] shifted_out;

  // テスト対象 (DUT) のインスタンス化 [cite: 14]
  shifter #(.N(N), .shift(shift)) dut (.*);

  initial begin
    $monitor("Time=%0t | in=%d (bin:%b) | out=%d (bin:%b)", 
              $time, shifter_in, shifter_in, shifted_out, shifted_out);

    // ケース1: 正の数 (8 / 4 = 2) 
    shifter_in = 8'd8; 
    #10;

    // ケース2: 負の数 (-8 / 4 = -2) 符号拡張されるはず 
    shifter_in = -8'd8; 
    #10;

    // ケース3: 最大値付近
    shifter_in = 8'd120;
    #10;

    $display("shifter Testbench finished.");
    $finish;
  end
endmodule