// ニューロン T 個をまとめたタイル。WTA の抑制線を区切る単位。
// タイル内の発火をまとめた any を wta_rail へ返し、wta_rail から戻ってくる inh を全員に配る。
// (自分の発火を打ち消す処理は membrane 側で行う)
module neuron_tile #(
    parameter int WIDTH   = 16,  // 膜電位 v のビット幅 (符号付き)
    parameter int W_WIDTH = 8,   // 重みのビット幅 (符号付き)
    parameter int N_IN    = 8,   // 1 ニューロンの入力本数 (eFPGA が引けるファンイン)
    parameter int T       = 8,   // このタイルのニューロン数
    parameter int INH     = 8,   // WTA の抑制量
    parameter int NEU_AW  = (T <= 1) ? 1 : $clog2(T)   // 導出用 (上書きしない)
) (
    input  logic                        clk,
    input  logic                        rst_n,

    input  logic signed [WIDTH-1:0]     v_th,        // 閾値 (タイル内で共通)
    input  logic [T-1:0][N_IN-1:0]      s_in,        // 各ニューロンの入力。s_in[i][j] = ニューロン i の j 本目
    input  logic                        inh,         // wta_rail からのグループ信号

    // 重み書き込み (このタイル宛てのときだけ w_we が 1)
    input  logic                        w_we,
    input  logic [NEU_AW-1:0]           w_neuron,    // タイル内のどのニューロンか
    input  logic [$clog2(N_IN)-1:0]     w_addr,      // そのニューロンの何本目か
    input  logic signed [W_WIDTH-1:0]   w_data,

    output logic [T-1:0]                s_out,       // 各ニューロンの発火
    output logic                        any          // タイル内の発火の OR → wta_rail (組み合わせ)
);
    genvar i;
    generate
        for (i = 0; i < T; i++) begin : g_neu
            membrane #(
                .WIDTH  (WIDTH),
                .W_WIDTH(W_WIDTH),
                .N_IN   (N_IN),
                .INH    (INH)
            ) u_neu (
                .w_we  (w_we && (w_neuron == i[NEU_AW-1:0])),  // 自分宛てのときだけ書く
                .w_addr(w_addr),
                .w_data(w_data),
                .clk   (clk),
                .rst_n (rst_n),
                .v_th  (v_th),
                .s_in  (s_in[i]),
                .inh   (inh),                                  // タイル内の全員に同じものを配る
                .s_out (s_out[i])
            );
        end
    endgenerate

    // タイル内で誰か 1 人でも発火したか
    assign any = |s_out;

endmodule
