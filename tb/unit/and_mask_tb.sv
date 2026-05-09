`timescale 1ns / 1ps

module and_mask_tb;

  // 1. パラメータと信号の定義
  parameter int N = 8;
  
  logic signed [N-1:0] input_bits;
  logic                mask_bit;
  logic signed [N-1:0] output_bits;

  // 2. テスト対象 (DUT) のインスタンス化
  and_mask #(
    .N(N)
  ) dut (
    .input_bits(input_bits),
    .mask_bit(mask_bit),
    .output_bits(output_bits)
  );

  // 3. テストシナリオ
  initial begin
    // モニター表示
    $monitor("Time=%0t | mask=%b | input=%b (%d) | output=%b (%d)", 
              $time, mask_bit, input_bits, input_bits, output_bits, output_bits);

    // --- テスト開始 ---

    // ケース1: maskが0のとき（何を入力しても0になるはず）
    mask_bit = 1'b0;
    input_bits = 8'b10101010; // 10進数で -86
    #10;

    input_bits = 8'b11110000; // 10進数で -16
    #10;

    // ケース2: maskを1にする（入力がそのまま出力されるはず）
    mask_bit = 1'b1;
    input_bits = 8'b10101010; 
    #10;

    input_bits = 8'b01111111; // 10進数で 127 (最大値)
    #10;

    // ケース3: 途中でmaskを0に戻す
    mask_bit = 1'b0;
    #10;

    $display("and_mask Testbench finished.");
    $finish;
  end

endmodule