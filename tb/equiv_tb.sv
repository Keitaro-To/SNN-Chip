// LIF 版: 直列版は k=15 で回す。WIDTH=16 で v < 2^15 なので漏れは常に 0 になり、IF の並列版と一致するはず
// (漏れを足しても、漏れが 0 のときに元の動きを壊していないことの確認)。
// 直列版 neuron_array (rtl/) と並列版 rtl_ref_parallel_if/neuron_array (module 名に _ref を付けた写し) に
// 同じランダム刺激を与え、ステップごとに全ニューロンの s_out と v が一致することを確かめる。
// 実行: python scripts/run_equiv.py (並列版の写しを作って iverilog にかける)
//
// 時間の対応: 直列版の 1 ステップ (N_IN+2 サイクル) = 並列版の 1 サイクル。
//   並列版には clk_p を与える。clk_p は直列版の UPDATE のサイクルにだけ立つ (立ち上がりは UPDATE の終わりの posedge)。
//   その posedge で、直列版はステップを終え、並列版は 1 ステップ進む。両方の s_out が同じエッジで変わる。
// 刺激: s_in はステップの間保持 (直列版の要件)。並列版にとっては clk_p の 1 サイクル分なので「1 ステップ 1 パルス」と同じ。
//   各ニューロンの 0 本目は隣のニューロンの s_out を戻す (eFPGA での結線の代わり。dut は dut の、ref は ref の s_out)。
//   残りの 7 本は外部からのランダム入力 (各本 25%)。
// 設定 (重み・link・wta_en) は走らせる前に書く。並列版は clk_p でしか書けないので、1 ステップ分の間 cfg を保持する。
`timescale 1ns/1ps
module equiv_tb;
    localparam int WIDTH = 16, W_WIDTH = 8, N_IN = 8, T = 8, NT = 13, INH = 8;
    localparam int N_NEU  = T * NT;
    localparam int STEP   = N_IN + 2;
    int STEPS = 20000;   // +steps=N で変えられる
    // neuron_array の導出パラメータ (同じ式)
    localparam int TILE_AW = $clog2(NT), NEU_AW = $clog2(T), W_AW = $clog2(N_IN);
    localparam int IDX_AW  = (NT > NT-1) ? $clog2(NT) : $clog2(NT-1);
    localparam int WADDR_W = TILE_AW + NEU_AW + W_AW;
    localparam int CFG_AW  = 1 + ((WADDR_W > IDX_AW + 1) ? WADDR_W : IDX_AW + 1);

    logic clk = 0, rst_n = 0;
    logic signed [WIDTH-1:0]   v_th;
    logic [N_NEU-1:0][N_IN-1:0] s_in_dut, s_in_ref;
    logic [N_NEU-1:0]          s_dut, s_ref;
    logic [N_NEU*N_IN-1:0]     ext;       // 外部入力 (両方に同じもの)。ext[n*N_IN+j] = ニューロン n の j 本目
    logic                      cfg_we;
    logic [CFG_AW-1:0]         cfg_addr;
    logic signed [W_WIDTH-1:0] cfg_data;
    logic                      step_end, done;

    // 並列版のクロック: 直列版の UPDATE のサイクルにだけ立つ。
    // リセットは同期式なので、リセット中 (rst_n=0) は通常のクロックを渡してリセットを効かせる
    logic en_p = 0, clk_p;
    always @(negedge clk) en_p <= step_end;
    assign clk_p = rst_n ? (clk & en_p) : clk;

    neuron_array #(.WIDTH(WIDTH), .W_WIDTH(W_WIDTH), .N_IN(N_IN), .T(T), .NT(NT), .INH(INH)) dut (
        .clk(clk), .rst_n(rst_n), .v_th(v_th), .k(4'd15), .s_in(s_in_dut), .s_out(s_dut),
        .step_end(step_end), .done(done), .cfg_we(cfg_we), .cfg_addr(cfg_addr), .cfg_data(cfg_data));
    neuron_array_ref #(.WIDTH(WIDTH), .W_WIDTH(W_WIDTH), .N_IN(N_IN), .T(T), .NT(NT), .INH(INH)) ref_ (
        .clk(clk_p), .rst_n(rst_n), .v_th(v_th), .s_in(s_in_ref), .s_out(s_ref),
        .cfg_we(cfg_we), .cfg_addr(cfg_addr), .cfg_data(cfg_data));

    // 0 本目は隣 (n+1) の s_out を戻す。残りは外部入力 (iverilog は可変添字の 2 次元 packed 配列を扱えないので generate で結線)
    // 膜電位も並べる (階層参照は定数添字のみ)
    logic signed [WIDTH-1:0] v_dut [N_NEU], v_ref [N_NEU];
    genvar gt, gi, gj;
    generate
        for (gt = 0; gt < NT; gt++) begin : g_t
            for (gi = 0; gi < T; gi++) begin : g_i
                localparam int N = gt*T + gi;
                assign s_in_dut[N][0] = s_dut[(N + 1) % N_NEU];
                assign s_in_ref[N][0] = s_ref[(N + 1) % N_NEU];
                for (gj = 1; gj < N_IN; gj++) begin : g_j
                    assign s_in_dut[N][gj] = ext[N*N_IN + gj];
                    assign s_in_ref[N][gj] = ext[N*N_IN + gj];
                end
                assign v_dut[N] = dut .g_tile[gt].u_tile.g_neu[gi].u_neu.v;
                assign v_ref[N] = ref_.g_tile[gt].u_tile.g_neu[gi].u_neu.v;
            end
        end
    endgenerate

    always #5 clk = ~clk;

    // 1 ステップ分 cfg を保持して書く (並列版は clk_p の 1 回、直列版は 10 回同じ値を書く)
    task automatic cfg_write(input logic [CFG_AW-1:0] addr, input logic signed [W_WIDTH-1:0] data);
        cfg_we = 1; cfg_addr = addr; cfg_data = data;
        repeat (STEP) @(negedge clk);
        cfg_we = 0;
    endtask

    int mismatches = 0, fires = 0, v_mism = 0, inh_steps = 0;
    int seed, dummy;
    initial begin
        if (!$value$plusargs("seed=%d", seed)) seed = 1;
        if ($value$plusargs("steps=%d", dummy)) STEPS = dummy;
        dummy = $urandom(seed);  // 乱数列を seed で決める
        v_th = 16'sd40; ext = '0; cfg_we = 0; cfg_addr = '0; cfg_data = '0;
        repeat (3) @(posedge clk);
        rst_n = 1;
        // 切れ目に合わせる
        @(negedge clk); while (!done) @(negedge clk);

        // 重み (全ニューロン × N_IN 本)
        for (int n = 0; n < N_NEU; n++)
            for (int j = 0; j < N_IN; j++)
                cfg_write({1'b0, (WADDR_W)'(n * N_IN + j)}, $urandom_range(0, 255) - 128);
        // link (ランダム) と wta_en (全部 1)
        for (int t = 0; t < NT - 1; t++)
            cfg_write((CFG_AW)'((1 << (CFG_AW-1)) | t), $urandom_range(0, 1));
        for (int t = 0; t < NT; t++)
            cfg_write((CFG_AW)'((1 << (CFG_AW-1)) | (1 << IDX_AW) | t), 1);

        for (int s = 0; s < STEPS; s++) begin
            // 切れ目 (done=1 のサイクル) の negedge で次のステップの入力を出す
            for (int k = 0; k < N_NEU * N_IN; k++)
                ext[k] = ($urandom_range(0, 3) == 0);   // 0 本目の分も引くが結線されないので無視される
            // LIF 版では v_th を途中で変えない。v != 0 なら入力なしでも毎ステップ更新するので、
            // v_th を v 以下に下げると IF 版 (入力なしは更新しない) と違って発火する (仕様としては正しい)
            repeat (STEP) @(negedge clk);
            if (!done) begin $display("MISALIGNED at %0t", $time); mismatches++; end
            // 切れ目で照合
            if (s_dut !== s_ref) begin
                mismatches++;
                if (mismatches <= 5) $display("s_out mismatch at step %0d: dut=%h ref=%h", s, s_dut, s_ref);
            end
            for (int n = 0; n < N_NEU; n++)
                if (v_dut[n] !== v_ref[n]) begin
                    v_mism++;
                    if (v_mism <= 5) $display("v mismatch at step %0d neuron %0d: dut=%0d ref=%0d", s, n, v_dut[n], v_ref[n]);
                end
            fires += $countones(s_ref);
            if (|s_ref) inh_steps++;
        end
        $display("EQUIV %s: steps=%0d neurons=%0d fires=%0d steps_with_fire=%0d s_out_mismatch_steps=%0d v_mismatches=%0d",
                 (mismatches == 0 && v_mism == 0) ? "PASS" : "FAIL", STEPS, N_NEU, fires, inh_steps, mismatches, v_mism);
        $finish;
    end
endmodule
