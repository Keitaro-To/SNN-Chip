`timescale 1ns / 1ps

module cnt_tb;

  // 1. パラメータと信号の定義
  parameter int N = 4;           // 4ビット（0〜15）でテスト
  parameter int rst_value = 0;
  
  logic clk;
  logic cnt_en;
  logic cnt_rst_n;
  logic [N-1:0] cnt_out;

  // 2. テスト対象 (DUT) のインスタンス化
  // .* を使うと、ポート名と信号名が同じ場合に自動で接続してくれます
  cnt #(
    .N(N),
    .rst_value(rst_value)
  ) dut (.*);

  // 3. クロックの生成 (10ns周期 = 100MHz)
  initial clk = 0;
  always #5 clk = ~clk;

  // 4. テストシナリオ
  initial begin
    // モニター表示
    $monitor("Time=%0t | rst_n=%b | en=%b | out=%d (%b)", 
              $time, cnt_rst_n, cnt_en, cnt_out, cnt_out);

    // --- テスト開始 ---

    // ケース1: 起動直後のリセット
    cnt_rst_n = 1'b0; cnt_en = 1'b0;
    #12; // クロックの立ち上がりを1回超えるまで待つ
    
    cnt_rst_n = 1'b1;
    #10;

    // ケース2: カウントアップ開始
    $display("--- Start Counting ---");
    cnt_en = 1'b1;
    #100; // 10クロック分くらい放置

    // ケース3: 途中で一時停止 (Enableを0にする)
    $display("--- Pause ---");
    cnt_en = 1'b0;
    #30;  // 3クロック分停止

    // ケース4: 再開
    $display("--- Resume ---");
    cnt_en = 1'b1;
    #40;

    // ケース5: カウント中にリセットを叩く
    $display("--- Emergency Reset ---");
    cnt_rst_n = 1'b0;
    #10;
    cnt_rst_n = 1'b1;
    #20;

    $display("Counter Testbench finished.");
    $finish;
  end

endmodule