`timescale 1ns / 1ps

module multi_cycle_tb;

  // 1. パラメータと信号の定義
  parameter int cycles_cnt_bitwidth = 4;
  parameter int n_cycles            = 5;

  logic clk;
  logic rst_n;
  logic start;
  logic all_ready;
  logic ready;
  logic restart;
  logic start_all;

  // 2. テスト対象 (DUT) のインスタンス化
  multi_cycle #(
    .cycles_cnt_bitwidth(cycles_cnt_bitwidth),
    .n_cycles(n_cycles)
  ) dut (.*);

  // 3. クロック生成 (10ns周期)
  initial clk = 0;
  always #5 clk = ~clk;

  // 4. テストシナリオ
  initial begin
    // モニター表示
    // iverilogでのクラッシュを避けるため、階層参照は最小限にします
    $monitor("Time=%0t | State=%0d | ready=%b | restart=%b | start_all=%b | all_ready=%b", 
              $time, dut.control_unit.present_state, ready, restart, start_all, all_ready);

    // --- A. 初期リセット ---
    rst_n = 0; start = 0; all_ready = 0;
    #12 rst_n = 1; // MC_RESET -> MC_IDLE_WAIT へ遷移 [cite: 54]
    
    // --- B. アイドル待機 (MC_IDLE_WAIT -> MC_IDLE) ---
    // 他のブロックが準備完了(all_ready=1)になるのを待つ [cite: 55]
    #10 all_ready = 1;
    #10; // ここで ready=1 (MC_IDLE) になるはず 

    // --- C. 計算開始 (MC_IDLE -> MC_INIT -> MC_UPDATE_WAIT) ---
    $display("--- Starting Multi-Cycle Operation ---");
    start = 1;
    #10 start = 0; 
    // MC_INIT で restart=1 が出力されることを確認 

    // --- D. ループ計算のシミュレーション ---
    // all_ready が 1 の間、MC_NETWORK_UPDATE と MC_UPDATE_WAIT を繰り返します
    // n_cycles=5 の場合、stop信号が出るまでループします [cite: 60, 61]
    
    repeat (20) begin // 念のため少し多めに回します
      #10; 
    end

    $display("Multi-Cycle test finished.");
    $finish;
  end

endmodule