`timescale 1ns / 1ps

module reg_sync_rst_tb;

  parameter int N = 8;
  logic clk;
  logic en;
  logic rst_n;
  logic [N-1:0] reg_in;
  logic [N-1:0] reg_out;

  // テスト対象 (DUT) のインスタンス化 [cite: 11]
  reg_sync_rst #(.N(N)) dut (.*);

  // クロック生成 (10ns 周期)
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $monitor("Time=%0t | rst_n=%b | en=%b | in=%h | out=%h", $time, rst_n, en, reg_in, reg_out);

    // 初期化：リセットをかける 
    rst_n = 0; en = 0; reg_in = 8'hAA;
    #12;
    
    // リセット解除、まだ Enable は 0 
    rst_n = 1;
    #10;

    // データ書き込み：Enable を 1 にする 
    en = 1; reg_in = 8'h55;
    #10;
    
    // Enable を 0 にして、入力が変わっても保持されるか確認
    en = 0; reg_in = 8'hFF;
    #10;

    // 同期リセットの確認：クロックに同期して '0' になるか 
    rst_n = 0;
    #10;

    $display("reg_sync_rst Testbench finished.");
    $finish;
  end
endmodule