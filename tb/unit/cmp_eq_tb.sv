`timescale 1ns / 1ps

module cmp_eq_tb;

  parameter int N = 4;
  logic [N-1:0] in0;
  logic [N-1:0] in1;
  logic         cmp_out;

  // テスト対象 (DUT) のインスタンス化 
  cmp_eq #(.N(N)) dut (
    .in0(in0),
    .in1(in1),
    .cmp_out(cmp_out)
  );

  initial begin
    $monitor("Time=%0t | in0=%b, in1=%b | eq_out=%b", $time, in0, in1, cmp_out);

    // ケース1: 完全一致
    in0 = 4'b1010; in1 = 4'b1010; #10; // cmp_out = 1 のはず

    // ケース2: 1ビットだけ違う
    in0 = 4'b1010; in1 = 4'b1011; #10; // cmp_out = 0 のはず

    // ケース3: 全ビット違う
    in0 = 4'b1111; in1 = 4'b0000; #10; // cmp_out = 0 のはず

    // ケース4: 0同士の一致
    in0 = 4'b0000; in1 = 4'b0000; #10; // cmp_out = 1 のはず

    $display("cmp_eq Testbench finished.");
    $finish;
  end
endmodule