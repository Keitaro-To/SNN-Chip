// IF ニューロン (符号付き重み / 即時発火 / 0 ハードリセット / WTA の抑制入力つき)
// membrane_parallel/membrane.sv の符号付き版。重みが負なら抑制性の結合になる。
//
// 更新のトリガー: 入力スパイクがあるか、抑制が来ているサイクル (|s_in || inh_me)。
//   - s_in は 1 タイムステップにつき 1 サイクルのパルス (保持すると複数ステップとして数える)
//   - inh は wta_rail から来るグループ信号 (グループ内の誰かが発火した)
//   - wta_rail は組み合わせ回路なので、inh は「今このサイクルの s_out」に対応する。
//     自分の発火で自分を抑制しないよう、自分の s_out で打ち消す
//
// 1 ステップの更新式 (抑制は閾値判定の前に引く):
//   v_new = v + sum - (抑制されていれば INH)
//   発火  = (v_new >= v_th)
//   v     <= 発火なら 0、負なら 0、それ以外は v_new
//
// 前提:
//   - v_th >= 1
//   - WIDTH >= W_WIDTH + clog2(N_IN) + 1 (sum と v_new が桁あふれしない幅)
//   - 重み書き込み中 (w_we) は s_in = 0 にすること (上位 FSM が保証)
module membrane #(
    parameter int WIDTH   = 16,  // 膜電位 v のビット幅 (符号付き)
    parameter int W_WIDTH = 8,   // 重みのビット幅 (符号付き: -128〜+127)
    parameter int N_IN    = 8,   // 前ニューロンとの接続数
    parameter int INH     = 8    // WTA の抑制量 (抑制されたステップに引く値)
) (
    // 初期重み書き込み
    input  logic                        w_we,    // 書き込みイネーブル
    input  logic [$clog2(N_IN)-1:0]     w_addr,  // どの重みか
    input  logic signed [W_WIDTH-1:0]   w_data,  // 書き込む値 (負なら抑制性)

    input  logic                        clk,
    input  logic                        rst_n,

    input  logic signed [WIDTH-1:0]     v_th,    // 閾値 (1 以上)
    input  logic [N_IN-1:0]             s_in,    // 入力スパイク (1ステップ1サイクルのパルス)
    input  logic                        inh,     // グループ内の誰かが発火した (WTA の抑制)

    output logic                        s_out    // 発火 (1サイクルのパルス)
);
    logic signed [WIDTH-1:0]   v;                    // 膜電位 (0 以上に保つ)
    logic signed [W_WIDTH-1:0] weight [N_IN-1:0];    // 重み (正=興奮性 / 負=抑制性)
    logic signed [WIDTH-1:0]   sum;                  // 今サイクルに入ってきた重みの合計
    logic signed [N_IN-1:0][WIDTH-1:0]   term;          // スパイクのある入力の重み (無ければ 0)
    logic signed [WIDTH:0]     v_new;                // v + sum - 抑制。1bit 広くして桁あふれを防ぐ
    logic                      inh_me;               // 自分に効く抑制
    logic                      fire;

    always_ff @(posedge clk) begin
        if (w_we) begin
            weight[w_addr] <= w_data;
        end
    end

    // 先に各入力の重みをマスクし (スパイク無しなら 0)、あとから条件なしで全部足す。
    // if 付きで足すと加算器と mux が N_IN 段の鎖になるが、条件なしの連続加算なら
    // Yosys が 1 つの多入力加算 ($macc) にまとめ、桁上げ保存の木に変換する。
    // WIDTH'(weight[i]) で 8b→16b に符号拡張してから AND するので 2 の補数は保たれる
    always_comb begin
        for (int i = 0; i < N_IN; i++) begin
            term[i] = WIDTH'(weight[i]) & {WIDTH{s_in[i]}};
        end
        sum = '0;
        for (int i = 0; i < N_IN; i++) begin
            sum = sum + term[i];
        end
    end


    // inh は今このサイクルの発火に対応する。自分が発火しているなら自分は抑制しない
    assign inh_me = inh && !s_out;

    // 組み合わせ回路: 抑制を引いたあとの膜電位。閾値判定もこの値で行う
    assign v_new = inh_me ? (v + sum - WIDTH'(INH)) : (v + sum);
    assign fire  = (v_new >= v_th);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            v     <= '0;
            s_out <= 1'b0;
        end else begin
            s_out <= 1'b0;
            if (|s_in || inh_me) begin
                if (fire) begin
                    v     <= '0;      // ハードリセット (超過分は捨てる)
                    s_out <= 1'b1;    // 発火 (1サイクルパルス)
                end else if (v_new < 0) begin
                    v     <= '0;      // 抑制で負になったら 0 で止める
                end else begin
                    v     <= v_new[WIDTH-1:0];
                end
            end
        end
    end

endmodule
