`timescale 1ns/1ps
// membrane (直列版 WTA の LIF: シフト減算の漏れ / 符号付き重み / 抑制入力つき / 負クランプあり / FSM は step_ctrl) のテストベンチ。
// step_ctrl はリセット後に止まらず回る。1ステップ = N_IN+2 サイクル。
// s_in と inh はステップの間保持し、切れ目 (done=1 のサイクル) でだけ変える。
// 各ステップの切れ目で v / s_out / active (そのステップで v を触ったか) を期待値と照合する。
// シナリオ:
//   1) w_we で重み8本をロード (正と負を混ぜる)
//   2) 正の重みの積算
//   3) 負の重みで v が下がる (符号拡張の確認)
//   4) 抑制だけのステップ (入力なし) で active になり、v から INH を引く
//   5) 入力も抑制も無いステップは active にならず v が動かない
//   6) 入力と抑制が同じステップに来たとき、抑制を引いてから閾値判定する
//   7) 発火した次のステップは、何もしなくても s_out が 0 に戻る (毎ステップ書き換え)
//   8) 発火中 (s_out=1) は自分を抑制しない
//   9) 負クランプ: 抑制や負の重みで v が負になったら 0 で止まり、その後また積める
//   1)〜9) は k=15 で行う (WIDTH=16 で v < 2^15 なので漏れは 0 = IF と同じ期待値)
//  10) 漏れ (k=2): 入力なしでも v - (v>>2) で下がり、v < 4 で止まる (active は 0 のまま)
//  11) 漏れ + 入力: v - (v>>k) + sum。漏れを引いてから閾値判定する
//  12) 漏れ + 抑制で負になったら 0 で止まる
//  13) k=0: v - v = 0 で毎ステップ全部抜ける。v=0 になったら止まる
module membrane_tb;

  localparam int WIDTH   = 16;
  localparam int W_WIDTH = 8;
  localparam int N_IN    = 8;
  localparam int INH     = 8;
  localparam int STEP    = N_IN + 2;  // 1ステップのサイクル数

  localparam logic signed [WIDTH-1:0] V_TH = 16'sd16;

  // 重み: w[0]=3, w[1]=5, w[2]=-2, w[3]=1, w[4]=4, w[5]=-7, w[6]=2, w[7]=6
  // (Icarus は localparam の配列初期化に未対応なので initial で代入)
  logic signed [W_WIDTH-1:0] w_init [N_IN];
  initial begin
    w_init[0] =  8'sd3;  w_init[1] =  8'sd5;  w_init[2] = -8'sd2;  w_init[3] = 8'sd1;
    w_init[4] =  8'sd4;  w_init[5] = -8'sd7;  w_init[6] =  8'sd2;  w_init[7] = 8'sd6;
  end

  logic                          clk = 1'b0;
  logic                          rst_n;
  logic                          w_we;
  logic [$clog2(N_IN)-1:0]       w_addr;
  logic signed [W_WIDTH-1:0]     w_data;
  logic signed [WIDTH-1:0]       v_th;
  logic [3:0]                    k;
  logic [N_IN-1:0]               s_in;
  logic                          inh;
  logic                          s_out;

  logic [$clog2(N_IN)-1:0]       idx;
  logic                          acc_en, inh_en, update_en, done;

  int errors = 0;

  // active は組み合わせ信号で、切れ目では s_out が書き換わった後の値を指してしまう (inh_me が変わる)。
  // そこでステップの途中 (INH のサイクル) で取り込んだ値を照合に使う
  logic act_seen;
  always @(posedge clk) if (inh_en) act_seen <= dut.active;

  step_ctrl #(
    .N_IN(N_IN)
  ) u_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .idx(idx),
    .acc_en(acc_en),
    .inh_en(inh_en),
    .update_en(update_en),
    .done(done)
  );

  membrane #(
    .WIDTH(WIDTH),
    .W_WIDTH(W_WIDTH),
    .N_IN(N_IN),
    .INH(INH)
  ) dut (
    .w_we(w_we),
    .w_addr(w_addr),
    .w_data(w_data),
    .clk(clk),
    .rst_n(rst_n),
    .v_th(v_th),
    .k(k),
    .s_in(s_in),
    .inh(inh),
    .idx(idx),
    .acc_en(acc_en),
    .inh_en(inh_en),
    .update_en(update_en),
    .s_out(s_out)
  );

  always #5 clk = ~clk; // 100MHz相当

  // 重み1本をロード (1サイクル)
  task automatic load_weight(input logic [$clog2(N_IN)-1:0] addr,
                             input logic signed [W_WIDTH-1:0] data);
    w_we   <= 1'b1;
    w_addr <= addr;
    w_data <= data;
    @(posedge clk);
    w_we   <= 1'b0;
  endtask

  // 1タイムステップ実行して照合 (切れ目 = done=1 の negedge で呼ぶこと):
  // s_in と inh を STEP サイクル保持し、次の切れ目で v / s_out / active (INH で取り込んだ値) を見る。
  task automatic step_chk(input logic [N_IN-1:0]         spikes,
                          input logic                    inhibit,
                          input logic signed [WIDTH-1:0] exp_v,
                          input logic                    exp_fire,
                          input logic                    exp_active);
    s_in <= spikes;
    inh  <= inhibit;
    repeat (STEP) @(negedge clk);
    if (!done) begin
      $display("[%0t] ** MISALIGNED ** done=0 at step boundary", $time);
      errors++;
    end
    if (dut.v !== exp_v || s_out !== exp_fire || act_seen !== exp_active) begin
      $display("[%0t] ** MISMATCH ** s_in=%b inh=%b: v=%0d (expect %0d), s_out=%b (expect %b), active=%b (expect %b)",
               $time, spikes, inhibit, dut.v, exp_v, s_out, exp_fire, act_seen, exp_active);
      errors++;
    end else begin
      $display("[%0t] s_in=%b inh=%b -> v=%0d s_out=%b %s", $time, spikes, inhibit,
               dut.v, s_out, act_seen ? "(active)" : "(idle)");
    end
  endtask

  initial begin
    $dumpfile("membrane_tb.vcd");
    $dumpvars(0, membrane_tb);

    rst_n = 0; w_we = 0; w_addr = '0; w_data = '0;
    v_th = V_TH; k = 4'd15; s_in = '0; inh = 1'b0;
    repeat (2) @(posedge clk);
    rst_n <= 1;
    @(posedge clk);

    // ---- 重みロード (s_in=0 のまま8サイクル。上位 FSM が保証する前提) ----
    $display("--- load weights: 3, 5, -2, 1, 4, -7, 2, 6 ---");
    for (int i = 0; i < N_IN; i++)
      load_weight(i[$clog2(N_IN)-1:0], w_init[i]);

    // ---- step_ctrl の切れ目 (done=1) に合わせる ----
    @(negedge clk);
    while (!done) @(negedge clk);

    // ---- 正の重みの積算: 0 -> 8 -> 12 ----
    $display("--- accumulate: expect v = 8, 12 ---");
    step_chk(8'b0000_0011, 1'b0,  16'sd8,  1'b0, 1'b1); // w0+w1 = 3+5 = 8
    step_chk(8'b0001_0000, 1'b0,  16'sd12, 1'b0, 1'b1); // +w4 = +4

    // ---- 負の重み: 12 -> 10 -> 3 ----
    $display("--- negative weights: expect v = 10, 3 ---");
    step_chk(8'b0000_0100, 1'b0,  16'sd10, 1'b0, 1'b1); // +w2 = -2
    step_chk(8'b0010_0000, 1'b0,  16'sd3,  1'b0, 1'b1); // +w5 = -7

    // ---- 正と負が同じステップ: 3 + (5 - 2 + 6) = 12 ----
    $display("--- mixed signs in one step: expect v = 12 ---");
    step_chk(8'b1000_0110, 1'b0,  16'sd12, 1'b0, 1'b1);

    // ---- 抑制だけのステップ: 入力なしでも active になり 12 - 8 = 4 ----
    $display("--- inhibition only: active without input, v = 4 ---");
    step_chk(8'b0000_0000, 1'b1,  16'sd4,  1'b0, 1'b1);

    // ---- 入力も抑制も無ければ active にならず v は動かない ----
    $display("--- idle: v must stay 4 ---");
    repeat (3) step_chk(8'b0000_0000, 1'b0,  16'sd4,  1'b0, 1'b0);

    // ---- 抑制を引いてから閾値判定: 4 + 18 - 8 = 14 < 16 なので発火しない ----
    // (抑制が無ければ 22 >= 16 で発火していた)
    $display("--- inhibition before threshold: 4 + 18 - 8 = 14, no fire ---");
    step_chk(8'b1001_0011, 1'b1,  16'sd14, 1'b0, 1'b1); // w0+w1+w4+w7 = 3+5+4+6 = 18

    // ---- 発火: 14 + 6 = 20 >= 16 ----
    $display("--- fire: expect v: 14 -> 0 with s_out=1 ---");
    step_chk(8'b1000_0000, 1'b0,  16'sd0,  1'b1, 1'b1); // +w7 = +6

    // ---- 発火の次のステップ: 何もしなくても s_out は 0 に戻る (active にならない) ----
    $display("--- step after fire (nothing): s_out returns to 0 without running ---");
    step_chk(8'b0000_0000, 1'b0,  16'sd0,  1'b0, 1'b0);

    // ---- 発火中は自分を抑制しない ----
    // 0 + 21 >= 16 で発火 (s_out=1)。次のステップで自分の発火がレールに乗って inh=1 になるが、
    // inh_me = inh && !s_out = 0 なので active にならず、v は 0 のまま。s_out は 0 に戻る
    $display("--- no self-inhibition while s_out=1 ---");
    step_chk(8'b1101_1011, 1'b0,  16'sd0,  1'b1, 1'b1); // w0+w1+w3+w4+w6+w7 = 21 -> fire
    step_chk(8'b0000_0000, 1'b1,  16'sd0,  1'b0, 1'b0); // 自分の発火による inh は無視

    // ---- 負クランプ: s_out=0 になったので inh が効く。0 - 8 = -8 -> 0 ----
    $display("--- clamp: inhibition at v=0 keeps v = 0 ---");
    step_chk(8'b0000_0000, 1'b1,  16'sd0,  1'b0, 1'b1);
    step_chk(8'b0000_0000, 1'b1,  16'sd0,  1'b0, 1'b1);

    // ---- 負クランプ: 3 + (-7) = -4 -> 0。負の重みでも 0 で止まる ----
    $display("--- clamp: 3 - 7 = -4 -> 0 ---");
    step_chk(8'b0000_0001, 1'b0,  16'sd3,  1'b0, 1'b1); // +w0 = +3
    step_chk(8'b0010_0000, 1'b0,  16'sd0,  1'b0, 1'b1); // +w5 = -7 -> 負 -> 0

    // ---- クランプ後に積み直せる: 0 -> 8 ----
    $display("--- recover after clamp: expect v = 8 ---");
    step_chk(8'b0000_0011, 1'b0,  16'sd8,  1'b0, 1'b1); // w0+w1 = 8

    // ---- 漏れ (k=2): 入力なしで 8 -> 6 -> 5 -> 4 -> 3 -> 3 (3>>2 = 0 で止まる) ----
    $display("--- leak k=2, idle: expect v = 6, 5, 4, 3, 3 ---");
    k = 4'd2;
    step_chk(8'b0000_0000, 1'b0,  16'sd6,  1'b0, 1'b0); // 8 - 2
    step_chk(8'b0000_0000, 1'b0,  16'sd5,  1'b0, 1'b0); // 6 - 1
    step_chk(8'b0000_0000, 1'b0,  16'sd4,  1'b0, 1'b0); // 5 - 1
    step_chk(8'b0000_0000, 1'b0,  16'sd3,  1'b0, 1'b0); // 4 - 1
    step_chk(8'b0000_0000, 1'b0,  16'sd3,  1'b0, 1'b0); // 3 - 0

    // ---- 漏れ + 入力: 3 - 0 + 8 = 11 -> 11 - 2 + 4 = 13 ----
    $display("--- leak + input: expect v = 11, 13 ---");
    step_chk(8'b0000_0011, 1'b0,  16'sd11, 1'b0, 1'b1); // +w0+w1
    step_chk(8'b0001_0000, 1'b0,  16'sd13, 1'b0, 1'b1); // +w4

    // ---- 漏れを引いてから閾値判定: 13 - 3 + 2 = 12 < 16 で発火しない (漏れが無ければ 15) ----
    // 続けて 12 - 3 + 6 = 15 < 16 (漏れが無ければ 18 で発火)、15 - 3 + 9 = 21 で発火
    $display("--- leak before threshold: 12, 15, then fire ---");
    step_chk(8'b0100_0000, 1'b0,  16'sd12, 1'b0, 1'b1); // +w6
    step_chk(8'b1000_0000, 1'b0,  16'sd15, 1'b0, 1'b1); // +w7
    step_chk(8'b1000_0011, 1'b0,  16'sd0,  1'b1, 1'b1); // +w0+w1+w7 = 14 -> 26 >= 16

    // ---- 漏れ + 抑制で負: 0 + 12 = 12 -> 12 - 3 - 7 - 8 = -6 -> 0 ----
    $display("--- leak + inhibition below 0: clamp to 0 ---");
    step_chk(8'b0001_0011, 1'b0,  16'sd12, 1'b0, 1'b1); // w0+w1+w4 = 12 (発火の次のステップ)
    step_chk(8'b0010_0000, 1'b1,  16'sd0,  1'b0, 1'b1); // +w5 - INH
    step_chk(8'b0000_0000, 1'b0,  16'sd0,  1'b0, 1'b0); // v=0 は漏れても 0

    // ---- k=0: 0 + 8 = 8 -> 8 - 8 + 4 = 4 -> 4 - 4 = 0 -> 0 ----
    $display("--- k=0: v - v = 0 every step ---");
    k = 4'd0;
    step_chk(8'b0000_0011, 1'b0,  16'sd8,  1'b0, 1'b1); // +w0+w1
    step_chk(8'b0001_0000, 1'b0,  16'sd4,  1'b0, 1'b1); // 8 - 8 + w4
    step_chk(8'b0000_0000, 1'b0,  16'sd0,  1'b0, 1'b0); // 4 - 4
    step_chk(8'b0000_0000, 1'b0,  16'sd0,  1'b0, 1'b0);

    if (errors == 0)
      $display("PASS: all checks passed. final v = %0d", dut.v);
    else
      $display("FAIL: %0d mismatch(es). final v = %0d", errors, dut.v);
    $finish;
  end

endmodule
