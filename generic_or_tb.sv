`timescale 1ns / 1ps

module generic_or_tb;

  // 1. パラメータと信号の定義
  parameter int N = 8; // 8入力のORとしてテスト
  
  logic [N-1:0] or_in;
  logic         or_out;

  // 2. テスト対象 (DUT) のインスタンス化
  generic_or #(.N(N)) dut (
    .or_in(or_in),
    .or_out(or_out)
  );

  // 3. テストシナリオ
  initial begin
    // モニター表示
    $monitor("Time=%0t | or_in=%b | or_out=%b", $time, or_in, or_out);

    // --- テスト開始 ---

    // ケース1: 全員0
    or_in = 8'b0000_0000;
    #10; // or_out = 0 のはず

    // ケース2: 1ビットだけ1にする (端っこ)
    or_in = 8'b0000_0001;
    #10; // or_out = 1 のはず

    // ケース3: 別の1ビットだけ1にする (真ん中)
    or_in = 8'b0001_0000;
    #10; // or_out = 1 のはず

    // ケース4: 複数ビットを1にする
    or_in = 8'b1010_1010;
    #10; // or_out = 1 のはず

    // ケース5: 全員1
    or_in = 8'b1111_1111;
    #10; // or_out = 1 のはず

    // ケース6: 再び全員0に戻す
    or_in = 8'b0000_0000;
    #10; // or_out = 0 に戻るはず

    $display("generic_or Testbench finished.");
    $finish;
  end

endmodule