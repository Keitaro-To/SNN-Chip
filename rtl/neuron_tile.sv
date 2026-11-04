// ニューロン T 個をまとめたタイル (直列版)。WTA の抑制線を区切る単位。
// rtl_ref_parallel_if/neuron_tile.sv に step_ctrl (ステップの合図) を 1 組足したもの。
// タイル内の T 個は同じ指令線で同じサイクルに同じ処理をする (動かないニューロンは自分の active で止まる)。
// タイル内の発火をまとめた any を wta_rail へ返し、wta_rail から戻ってくる inh を全員に配る。
// (自分の発火を打ち消す処理は membrane 側で行う)
module neuron_tile #(
    parameter int WIDTH   = 16,  // 膜電位 v のビット幅 (符号付き)
    parameter int W_WIDTH = 8,   // 重みのビット幅 (符号付き)
    parameter int N_IN    = 8,   // 1 ニューロンの入力本数 (eFPGA が引けるファンイン)
    parameter int T       = 8,   // このタイルのニューロン数
    parameter int INH     = 8,   // WTA の抑制量
    parameter int K_W     = 4,   // 漏れのシフト量 k のビット幅
    parameter int NEU_AW  = (T <= 1) ? 1 : $clog2(T)   // 導出用 (上書きしない)
) (
    input  logic                        clk,
    input  logic                        rst_n,

    input  logic signed [WIDTH-1:0]     v_th,        // 閾値 (タイル内で共通)
    input  logic [K_W-1:0]              k,           // 漏れのシフト量 (タイル内で共通)
    input  logic [T-1:0][N_IN-1:0]      s_in,        // 各ニューロンの入力 (1ステップ保持)。s_in[i][j] = ニューロン i の j 本目
    input  logic                        inh,         // wta_rail からのグループ信号

    // 重み書き込み (このタイル宛てのときだけ w_we が 1)
    input  logic                        w_we,
    input  logic [NEU_AW-1:0]           w_neuron,    // タイル内のどのニューロンか
    input  logic [$clog2(N_IN)-1:0]     w_addr,      // そのニューロンの何本目か
    input  logic signed [W_WIDTH-1:0]   w_data,

    output logic [T-1:0]                s_out,       // 各ニューロンの発火 (1ステップ保持)
    output logic                        any,         // タイル内の発火の OR → wta_rail (組み合わせ)
    output logic                        step_end,    // UPDATE のサイクル (このサイクルの終わりで s_in を切り替える)
    output logic                        done         // ステップ完了 (1パルス。v と s_out が確定)
);
    logic [$clog2(N_IN)-1:0] idx;
    logic acc_en, inh_en, update_en;

    step_ctrl #(
        .N_IN(N_IN)
    ) u_ctrl (
        .clk      (clk),
        .rst_n    (rst_n),
        .idx      (idx),
        .acc_en   (acc_en),
        .inh_en   (inh_en),
        .update_en(update_en),
        .done     (done)
    );

    assign step_end = update_en;

    genvar i;
    generate
        for (i = 0; i < T; i++) begin : g_neu
            membrane #(
                .WIDTH  (WIDTH),
                .W_WIDTH(W_WIDTH),
                .N_IN   (N_IN),
                .INH    (INH),
                .K_W    (K_W)
            ) u_neu (
                .w_we     (w_we && (w_neuron == i[NEU_AW-1:0])),  // 自分宛てのときだけ書く
                .w_addr   (w_addr),
                .w_data   (w_data),
                .clk      (clk),
                .rst_n    (rst_n),
                .v_th     (v_th),
                .k        (k),
                .s_in     (s_in[i]),
                .inh      (inh),                                  // タイル内の全員に同じものを配る
                .idx      (idx),
                .acc_en   (acc_en),
                .inh_en   (inh_en),
                .update_en(update_en),
                .s_out    (s_out[i])
            );
        end
    endgenerate

    // タイル内で誰か 1 人でも発火したか
    assign any = |s_out;

endmodule
