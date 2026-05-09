`timescale 1ns / 1ps

module add_sub_tb;

  parameter int N = 4;
  
  logic signed [N-1:0] in0;
  logic signed [N-1:0] in1;
  logic                add_or_sub;
  logic signed [N-1:0] add_sub_out;

  // テスト対象のインスタンス化
  add_sub #(
    .N(N)
  ) dut (
    .in0(in0),
    .in1(in1),
    .add_or_sub(add_or_sub),
    .add_sub_out(add_sub_out)
  );

  initial begin
    // iverilog用に$monitorをシンプルに変更（式を入れない）
    $monitor("Time=%0t | Op=%b | in0=%d, in1=%d | out=%d", 
              $time, add_or_sub, in0, in1, add_sub_out);

    // テストケース
    add_or_sub = 1'b0; in0 = 4'd2; in1 = 4'd3; #10;
    add_or_sub = 1'b0; in0 = 4'd5; in1 = 4'd4; #10; // +7にサチュレート
    add_or_sub = 1'b1; in0 = 4'd3; in1 = 4'd5; #10;
    add_or_sub = 1'b1; in0 = -4'd6; in1 = 4'd5; #10; // -8にサチュレート
    add_or_sub = 1'b0; in0 = 4'd7; in1 = 4'd0; #10;

    $display("Testbench finished.");
    $finish;
  end

endmodule