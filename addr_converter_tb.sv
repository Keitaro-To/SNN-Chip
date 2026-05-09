`timescale 1ns / 1ps

module addr_converter_tb;

  // 1. パラメータと信号の定義
  parameter int N = 4; // チェックしやすいように4ビットにします（0~15）
  
  logic [N-1:0] addr_in;
  logic [N-1:0] addr_out;

  // 2. テスト対象 (DUT) のインスタンス化
  addr_converter #(
    .N(N)
  ) dut (
    .addr_in(addr_in),
    .addr_out(addr_out)
  );

  // 3. テストシナリオ
  initial begin
    // モニター表示
    $monitor("Time=%0t | addr_in=%d (bin:%b) | addr_out=%d (bin:%b)", 
              $time, addr_in, addr_in, addr_out, addr_out);

    // --- テスト開始 ---

    // ケース1: 0を入れる -> 1が出るはず
    addr_in = 4'd0;
    #10;

    // ケース2: 5を入れる -> 6が出るはず
    addr_in = 4'd5;
    #10;

    // ケース3: 14を入れる -> 15が出るはず
    addr_in = 4'd14;
    #10;

    // ケース4: 最大値(15)を入れる -> 0に戻る（ロールオーバー）
    // 4ビットのハコ(0~15)で15+1をすると、0になります。
    addr_in = 4'd15;
    #10;

    $display("addr_converter Testbench finished.");
    $finish;
  end

endmodule