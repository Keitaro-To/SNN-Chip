// ステップの合図を出す controller (タイルに 1 組。ニューロンは FSM を持たない)。
// リセット後は止まらずに回り続け、全ニューロンに同じ指令線 (idx/acc_en/inh_en/update_en) を配る。
//   ACC ×N_IN (1本ずつ積算) → INH (抑制を引く) → UPDATE (判定・v更新・sum クリア) → ACC ...
// 1ステップ = N_IN+2 サイクル。sum のクリアは UPDATE のサイクルに同時に行う (別の状態は持たない)。
// 動くかどうか (入力も抑制も無いニューロンを止める) は各ニューロンが自分の active で指令線を門で止める。
// done は v と s_out が確定するサイクル (UPDATE の次 = 次ステップの先頭) に1パルス。
// 外から s_in を変えるのは UPDATE のサイクルの終わり (update_en=1 のサイクル) に合わせること。
module step_ctrl #(
    parameter int N_IN = 8
) (
    input  logic                        clk,
    input  logic                        rst_n,

    output logic [$clog2(N_IN)-1:0]     idx,        // 今サイクル処理する入力番号
    output logic                        acc_en,     // s_in[idx] があれば weight[idx] を sum に足す
    output logic                        inh_en,     // 抑制されていれば sum から INH を引く
    output logic                        update_en,  // 発火判定して v を更新する (ステップ末に1回)
    output logic                        done        // ステップ完了 (1パルス)
);
    typedef enum logic [1:0] {ACC, INH, UPDATE} state_t;
    state_t state;
    logic [$clog2(N_IN)-1:0] counter;

    assign idx       = counter;
    assign acc_en    = (state == ACC);
    assign inh_en    = (state == INH);
    assign update_en = (state == UPDATE);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state   <= ACC;
            counter <= '0;
            done    <= 1'b0;
        end else begin
            // v と s_out は UPDATE の「次の」サイクルに確定するので、done もそこに合わせる
            done <= update_en;
            case (state)
                ACC: begin
                    if (counter == N_IN-1) begin
                        counter <= '0;
                        state   <= INH;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
                INH:     state <= UPDATE;
                UPDATE:  state <= ACC;
                default: state <= ACC;
            endcase
        end
    end

endmodule
