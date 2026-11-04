// 直列版 LIF ニューロン (WTA 版): シフト減算の漏れ / 符号付き重み / 即時発火 / 0 ハードリセット / 負クランプ / WTA の抑制入力つき
// 漏れなし (IF) の直列版に、毎ステップの漏れ v - (v >> k) を足したもの。
// rtl_ref_parallel_if/membrane.sv (並列版) の更新式を、入力 1 本ずつの積算で実行する datapath。
// FSM は持たない。「いつ何をするか」はタイルの step_ctrl が指令線 (idx/acc_en/inh_en/update_en) で配る。
//
// 1ステップ = N_IN+2 サイクル。並列版のサイクル t が、この版のステップ t に対応する:
//   - s_in : 1ステップの間保持するレベル (並列版の 1 サイクルパルスに相当)。ステップの切れ目でだけ変える
//   - s_out: UPDATE で書き換え、次の UPDATE まで保持するレベル。発火しなければ 0 に戻るので、
//            並列版と同じ「ちょうど 1 ステップ幅のパルス」になる
//   - inh  : wta_rail から来るグループ信号。s_out (レベル) から作られるので 1 ステップ保持になる
//
// active = |s_in || inh_me は並列版の更新条件と同じ式。0 のステップは指令線を門で止めて何も動かさない
// (sum・重み選択・加算器が動かないので待機電力は並列版と同じ)。結果は止めなくても変わらない。
//
// 漏れ: v は 0 以上なので v >> k は 0 埋めの可変シフタ (k の各ビットで 1/2/4/8 ずらす MUX 4 段)。
//   k はタイル共通の入力 (v_th と同じ配り方)。k=0 なら v - v = 0 で毎ステップ全部抜ける (そのまま再現)。
//   v < 2^k では v >> k = 0 で漏れが止まる (切り捨て)。
// active (入力か抑制がある) でないステップも、v != 0 なら漏れのために UPDATE で v を書き換える。
// v = 0 なら漏れも 0 なので書き換えなくても結果は同じ (止めておく)。
//
// 更新式 (UPDATE の1サイクル、active または v != 0 のとき):
//   v_new = v - (v >> k) + sum   (sum には抑制 -INH まで反映済み)
//   発火 (v_new >= v_th) → v=0, s_out=1 / 負 (v_new < 0) → v=0 / それ以外 → v=v_new
//
// 前提: v_th >= 1 / WIDTH >= W_WIDTH + clog2(N_IN) + 1 / 重み書き込み中 (w_we) は s_in = 0 (上位が保証)
module membrane #(
    parameter int WIDTH   = 16,  // 膜電位 v のビット幅 (符号付き)
    parameter int W_WIDTH = 8,   // 重みのビット幅 (符号付き: -128〜+127)
    parameter int N_IN    = 8,   // 前ニューロンとの接続数
    parameter int INH     = 8,   // WTA の抑制量 (抑制されたステップに引く値)
    parameter int K_W     = 4    // 漏れのシフト量 k のビット幅 (k = 0〜2^K_W-1)
) (
    // 初期重み書き込み
    input  logic                        w_we,    // 書き込みイネーブル
    input  logic [$clog2(N_IN)-1:0]     w_addr,  // どの重みか
    input  logic signed [W_WIDTH-1:0]   w_data,  // 書き込む値 (負なら抑制性)

    input  logic                        clk,
    input  logic                        rst_n,

    input  logic signed [WIDTH-1:0]     v_th,    // 閾値 (1 以上)
    input  logic [K_W-1:0]              k,       // 漏れのシフト量 (1 ステップに v の 1/2^k を引く)
    input  logic [N_IN-1:0]             s_in,    // 入力スパイク (1ステップ保持)
    input  logic                        inh,     // グループ内の誰かが発火した (WTA の抑制)

    // step_ctrl からの指令線 (タイル内で共通)
    input  logic [$clog2(N_IN)-1:0]     idx,
    input  logic                        acc_en,
    input  logic                        inh_en,
    input  logic                        update_en,

    output logic                        s_out    // 発火 (1ステップ保持)
);
    logic signed [WIDTH-1:0]   v;                  // 膜電位 (0 以上に保つ)
    logic signed [W_WIDTH-1:0] weight [N_IN-1:0];  // 重み (正=興奮性 / 負=抑制性)
    logic signed [WIDTH-1:0]   sum;                // 今ステップに入ってきた重みの合計 (抑制込み)
    logic signed [WIDTH-1:0]   leak;               // v >> k (このステップに漏れる量)
    logic signed [WIDTH:0]     v_new;              // v - leak + sum。1bit 広くして桁あふれを防ぐ
    logic                      inh_me;             // 自分に効く抑制
    logic                      active;             // 入力か抑制があるか (並列版の更新条件)
    logic                      upd;                // このステップで v を書き換えるか (active か、漏れる v がある)

    // 自分のニューロンだけに効く指令線 (active で門を閉じる)
    logic [$clog2(N_IN)-1:0]   idx_l;
    logic                      acc_l, inh_l;

    always_ff @(posedge clk) begin
        if (w_we) begin
            weight[w_addr] <= w_data;
        end
    end

    // inh は s_out (レベル) から作られる。自分が発火しているなら自分は抑制しない
    assign inh_me = inh && !s_out;
    assign active = |s_in || inh_me;
    assign upd    = active || (v != '0);

    // 動かないステップは idx も止めて、重み選択回路と加算器の入力を変えない
    assign idx_l = active ? idx : '0;
    assign acc_l = acc_en && active;
    assign inh_l = inh_en && active;

    // 1サイクルに1本だけ加算 (並列版の加算木に対し、加算器はこの1個)。抑制も同じ加算器で引く。
    // sum は UPDATE で読むと同時に 0 に戻す (動かなかったニューロンは元から 0 なので何も変わらない)。
    // 符号付きどうしなので符号拡張される (8b→16b)。
    // 三項演算子に符号なしの '0 を混ぜると式全体が符号なし扱いになるので、if で書く
    always_ff @(posedge clk) begin
        if (!rst_n || update_en) begin
            sum <= '0;
        end else if (acc_l) begin
            if (s_in[idx_l]) sum <= sum + WIDTH'(weight[idx_l]);
        end else if (inh_l) begin
            if (inh_me) sum <= sum - WIDTH'(INH);
        end
    end

    // 組み合わせ回路: 「今この瞬間の v-leak+sum」(UPDATE 時点では sum は抑制まで反映済み)
    // v は 0 以上なので >> (0 埋め) でよい。v - leak は 0 以上 v 以下
    assign leak  = v >> k;
    assign v_new = v - leak + sum;

    // 漏れを入れた更新式を、update_en の1サイクルだけ実行
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            v     <= '0;
            s_out <= 1'b0;
        end else if (update_en) begin
            if (upd) begin
                if (v_new >= v_th) begin
                    v     <= '0;    // ハードリセット (超過分は捨てる)
                    s_out <= 1'b1;  // 発火 (次の UPDATE まで保持)
                end else if (v_new < 0) begin
                    v     <= '0;    // 抑制・負の重みで負になったら 0 で止める
                    s_out <= 1'b0;
                end else begin
                    v     <= v_new[WIDTH-1:0];
                    s_out <= 1'b0;  // 発火せず
                end
            end else begin
                s_out <= 1'b0;      // 動かなかったステップは発火なし (v はそのまま)
            end
        end
    end

endmodule
