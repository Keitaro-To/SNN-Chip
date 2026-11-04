// WTA の抑制線 (区間分割方式)。組み合わせ回路なのでクロックは持たない。
// タイルごとの発火 any[t] を受け取り、link でつながったタイル群の中に発火があったかを grp[t] として返す。
//   link[t] = 1 なら タイル t と t+1 は同じグループ (link はタイル境界の数 = NT-1 本)
//
// 区切りのある累積 OR (セグメント付きスキャン):
//   F[t] = any[t] | (link[t-1] & F[t-1])     前向き  (自分より前のタイルからの伝搬)
//   B[t] = any[t] | (link[t]   & B[t+1])     後ろ向き (自分より後ろのタイルからの伝搬)
//   grp[t] = F[t] | B[t]
// link が 0 の境界で伝搬が止まるので、そこがグループの切れ目になる。
//
// wta_en[t] = 0 のタイルは WTA に参加しない (抑制を受けないし、発火をレールにも流さない)。
// 参加しないタイルがあっても、そのタイルを通り越した伝搬は止まらない (link の連結はそのまま)。
//
// 組み合わせ回路なので、抑制は興奮と同じステップに効く (s_out が 1 のサイクルに grp も 1 になる)。
// そのかわりスキャンがニューロンのクリティカルパスに入る。タイル数が増えて遅くなるようなら、
// ここをレジスタで受ける (そのぶん抑制が 1 ステップ遅れる) 形に変える。
module wta_rail #(
    parameter int NT     = 8,   // タイル数 (2 以上)
    parameter int LINK_W = (NT <= 1) ? 1 : NT - 1   // 導出用 (上書きしない)
) (
    input  logic [NT-1:0]       any,     // タイルごとの発火
    input  logic [NT-1:0]        wta_en, // タイルごとの参加 (1 = WTA に参加 / 0 = 不参加)
    input  logic [LINK_W-1:0]   link,    // タイル境界の設定 (1 = つなぐ / 0 = 切る)

    output logic [NT-1:0]       grp      // そのタイルのグループ内に発火があった
);
    logic [NT-1:0] fire_in, fwd, bwd;

    // 参加しているタイルの発火だけをレールに流す
    assign fire_in = any & wta_en;

    always_comb begin
        // 前向き: 先頭のタイルには前がない
        fwd[0] = fire_in[0];
        for (int t = 1; t < NT; t++)
            fwd[t] = fire_in[t] | (link[t-1] & fwd[t-1]);

        // 後ろ向き: 末尾のタイルには後ろがない
        bwd[NT-1] = fire_in[NT-1];
        for (int t = NT-2; t >= 0; t--)
            bwd[t] = fire_in[t] | (link[t] & bwd[t+1]);

        // どちらの向きから来た発火も拾う。参加していないタイルには返さない
        for (int t = 0; t < NT; t++)
            grp[t] = (fwd[t] | bwd[t]) & wta_en[t];
    end

endmodule
