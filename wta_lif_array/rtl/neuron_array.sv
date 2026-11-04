// ニューロンアレイのトップ (直列版)。タイル NT 個と WTA の抑制線を束ね、設定の宛先を振り分ける。
// rtl_ref_parallel_if/neuron_array.sv と同じ構造で、タイルが直列版 (step_ctrl 内蔵) になり、step_end / done が増えた。
// LIF 版: 漏れのシフト量 k を v_th と同じく全ニューロン共通の入力として配る。
// 全タイルの step_ctrl は同じリセットから同じ周期で回るので、常に同じサイクルに同じ状態にいる。
// ニューロン同士の配線は eFPGA 側なので、ここでは全ニューロンの入力と出力を端子として出す。
//   s_in[n][j] = ニューロン n (全体番号 = タイル番号*T + タイル内番号) の j 本目の入力線 (1ステップ保持)
//   s_out[n]   = ニューロン n の発火 (1ステップ保持)
//   step_end   = UPDATE のサイクル。外から s_in を変えるのはこのサイクルの終わりに合わせる
//   done       = ステップ完了 (1パルス。v と s_out が確定)
//
// 設定書き込み (cfg_addr の最上位ビットで宛先を分ける):
//   cfg_addr[CFG_AW-1] = 0 : 重み    下位を { タイル番号, タイル内番号, 入力番号 } として使う
//                            cfg_data = 重みの値 (符号付き)
//   cfg_addr[CFG_AW-1] = 1 : 設定    cfg_addr[IDX_AW] = 0 なら link、1 なら wta_en
//                            cfg_addr[IDX_AW-1:0] = 何番目のビットか / cfg_data[0] = 書く値
//
// 例 (T=8, NT=13, N_IN=8 の場合): タイル 3 のニューロン 5 の 2 本目に 20 を書く
//   cfg_we = 1, cfg_addr = {1'b0, 4'd3, 3'd5, 3'd2}, cfg_data = 20
// 例: タイル 9 と 10 の境界をつなぐ (link[9] = 1)
//   cfg_we = 1, cfg_addr = {1'b1, 1'b0, 4'd9}, cfg_data = 1
module neuron_array #(
    parameter int WIDTH   = 16,  // 膜電位 v のビット幅 (符号付き)
    parameter int W_WIDTH = 8,   // 重みのビット幅 (符号付き)
    parameter int N_IN    = 8,   // 1 ニューロンの入力本数
    parameter int T       = 8,   // 1 タイルのニューロン数
    parameter int NT      = 8,  // タイル数
    parameter int INH     = 8,   // WTA の抑制量
    parameter int K_W     = 4,   // 漏れのシフト量 k のビット幅
    // 以下は導出用 (上書きしない)
    parameter int N_NEU   = T * NT,
    parameter int LINK_W  = (NT <= 1) ? 1 : NT - 1,
    parameter int TILE_AW = (NT <= 1) ? 1 : $clog2(NT),
    parameter int NEU_AW  = (T  <= 1) ? 1 : $clog2(T),
    parameter int W_AW    = $clog2(N_IN),
    parameter int IDX_AW  = (NT > LINK_W) ? $clog2(NT) : $clog2(LINK_W),
    parameter int WADDR_W = TILE_AW + NEU_AW + W_AW,
    parameter int CFG_AW  = 1 + ((WADDR_W > IDX_AW + 1) ? WADDR_W : IDX_AW + 1)
) (
    input  logic                        clk,
    input  logic                        rst_n,

    input  logic signed [WIDTH-1:0]     v_th,        // 閾値 (全ニューロン共通)
    input  logic [K_W-1:0]              k,           // 漏れのシフト量 (全ニューロン共通)
    input  logic [N_NEU-1:0][N_IN-1:0]  s_in,        // 全ニューロンの入力 (eFPGA から)。s_in[n][j]
    output logic [N_NEU-1:0]            s_out,       // 全ニューロンの発火 (eFPGA へ)
    output logic                        step_end,    // UPDATE のサイクル
    output logic                        done,        // ステップ完了 (1パルス)

    // 設定書き込み
    input  logic                        cfg_we,
    input  logic [CFG_AW-1:0]           cfg_addr,
    input  logic signed [W_WIDTH-1:0]   cfg_data
);

    // タイルとレールをつなぐ信号
    logic [NT-1:0]      any;       // タイルごとの発火      → wta_rail へ
    logic [NT-1:0]      grp;       // タイルごとの抑制      ← wta_rail から
    logic [NT-1:0]      tile_we;   // タイルごとの重み書き込みイネーブル (cfg_addr から作る)
    logic [NT-1:0]      tile_step_end, tile_done;  // タイルごとの合図 (全部同じ。タイル 0 のものを外へ出す)
    logic [NEU_AW-1:0]  a_neu;     // 書き込み先のタイル内番号 (cfg_addr から切り出す)
    logic [W_AW-1:0]    a_w;       // 書き込み先の入力番号     (cfg_addr から切り出す)

    // 設定レジスタ
    logic [LINK_W-1:0]  link;      // タイル境界 (1 = つなぐ)
    logic [NT-1:0]      wta_en;    // タイルごとの WTA 参加

    // ---- 設定アドレスの分解 ----
    logic               is_cfg;    // 0 = 重み / 1 = link・wta_en
    logic [TILE_AW-1:0] a_tile;    // 書き込み先のタイル番号
    logic               cfg_kind;  // 0 = link / 1 = wta_en
    logic [IDX_AW-1:0]  cfg_idx;   // 何番目のビットか

    assign is_cfg   = cfg_addr[CFG_AW-1];
    assign a_tile   = cfg_addr[NEU_AW+W_AW +: TILE_AW];
    assign a_neu    = cfg_addr[W_AW +: NEU_AW];
    assign a_w      = cfg_addr[W_AW-1:0];
    assign cfg_kind = cfg_addr[IDX_AW];
    assign cfg_idx  = cfg_addr[IDX_AW-1:0];

    // 重みの書き込みは、宛先のタイルだけイネーブルにする
    always_comb begin
        for (int t = 0; t < NT; t++)
            tile_we[t] = cfg_we && !is_cfg && (a_tile == t[TILE_AW-1:0]);
    end

    // ---- link と wta_en (1 ビットずつ書き込む) ----
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            link   <= '0;
            wta_en <= '0;
        end else if (cfg_we && is_cfg) begin
            if (!cfg_kind) link[cfg_idx]   <= cfg_data[0];
            else           wta_en[cfg_idx] <= cfg_data[0];
        end
    end

    genvar i;
    generate
        for (i = 0; i < NT; i++) begin : g_tile
            neuron_tile #(
                .WIDTH  (WIDTH),
                .W_WIDTH(W_WIDTH),
                .N_IN   (N_IN),
                .T      (T),
                .INH    (INH),
                .K_W    (K_W)
            ) u_tile (
                .clk      (clk),
                .rst_n    (rst_n),
                .v_th     (v_th),
                .k        (k),
                // 全体の入力から、このタイルのニューロン T 個ぶんを渡す
                .s_in     (s_in[i*T +: T]),
                .inh      (grp[i]),
                .w_we     (tile_we[i]),
                .w_neuron (a_neu),
                .w_addr   (a_w),
                .w_data   (cfg_data),
                // 全体の出力の、このタイルのぶん (T 本)
                .s_out    (s_out[i*T +: T]),
                .any      (any[i]),
                .step_end (tile_step_end[i]),
                .done     (tile_done[i])
            );
        end
    endgenerate

    assign step_end = tile_step_end[0];
    assign done     = tile_done[0];

    // ---- WTA の抑制線 ----
    wta_rail #(
        .NT(NT)
    ) u_rail (
        .any   (any),
        .wta_en(wta_en),
        .link  (link),
        .grp   (grp)
    );

endmodule
