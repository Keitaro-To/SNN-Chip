`timescale 1ns / 1ps
module barrier_tb;
  parameter int N = 8;
  logic clk, rst_n, restart, out_sample;
  logic [N-1:0] reg_in, reg_out;
  logic ready;

  barrier #(.N(N)) dut (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    // $monitor を極限までシンプルにします。
    // 状態名は「%0d」または「%0h」で数字として表示させるのが一番確実です。
    $monitor("Time=%0t | State_Num=%0d | in=%h | out=%h | ready=%b", 
              $time, dut.control_unit.present_state, reg_in, reg_out, ready);
    
    // --- シナリオ ---
    rst_n = 0; restart = 0; out_sample = 0; reg_in = 8'hAA; #12;
    rst_n = 1; #10;

    $display("--- Testing Restart ---");
    restart = 1; #10; restart = 0; #10;

    $display("--- Testing Sample ---");
    reg_in = 8'h55; out_sample = 1; #10; out_sample = 0; #10;

    $display("Barrier test finished.");
    $finish;
  end
endmodule