`timescale 1ns / 1ps

module cmp_gt_tb;

  parameter int N = 4; // 分かりやすく4ビット (-8 ~ +7)
  logic signed [N-1:0] in0;
  logic signed [N-1:0] in1;
  logic                cmp_out;

  // テスト対象 (DUT) のインスタンス化 [cite: 6]
  cmp_gt #(.N(N)) dut (
    .in0(in0),
    .in1(in1),
    .cmp_out(cmp_out)
  );

  initial begin
    $monitor("Time=%0t | in0=%d, in1=%d | gt_out=%b (in0 > in1)", $time, in0, in1, cmp_out);

    // ケース1: 正の数同士 (5 > 2)
    in0 = 4'd5; in1 = 4'd2; #10; // 1 (True)

    // ケース2: 正と負 (2 > -3)
    in0 = 4'd2; in1 = -4'd3; #10; // 1 (True)

    // ケース3: 負の数同士 (-2 > -1)
    in0 = -4'd2; in1 = -4'd1; #10; // 0 (False)

    // ケース4: 同じ値 (3 > 3)
    in0 = 4'd3; in1 = 4'd3; #10; // 0 (False: "より大きい"なので)

    // ケース5: 限界値の比較 (7 > -8)
    in0 = 4'd7; in1 = -4'd8; #10; // 1 (True)

    $display("cmp_gt Testbench finished.");
    $finish;
  end
endmodule