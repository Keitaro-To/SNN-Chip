# SNN-Chip — WTA 付き直列 LIF ニューロンアレイ (SystemVerilog)

音源定位など小規模エッジ向け SNN を狙った、**ニューロン部だけ**のハード実装です。
ニューロン同士の結線は外部 (eFPGA) に任せる前提で、アレイは全ニューロンの入力線と発火線を端子として出します。

- ニューロン: 漏れ付き積分発火 (LIF)。漏れは乗算を使わず **シフト減算** `v - (v >> k)` で 1 ステップに 1 回
- 競合: タイル単位の **Winner-Take-All (WTA)**。発火したタイル群の全員から一定量 `INH` を引く
- 面積優先の **直列演算**: 入力を 1 本ずつ積算し、1 ステップ = `N_IN + 2` サイクル。加算器はニューロンに 1 個
- 検証: 単体テストベンチと、並列 IF 版との **ステップ単位の等価性テスト** (漏れ 0 で完全一致)
- 評価: Yosys + ABC で Nangate45 に合成し、OpenSTA で遅延・電力を測定

## ディレクトリ

```
├─ rtl/                    設計本体 (合成対象)
│  ├─ membrane.sv            ニューロン 1 個のデータパス (重み・積算・漏れ・発火判定)
│  ├─ step_ctrl.sv           ステップの合図 (ACC ×N_IN → INH → UPDATE)。タイルに 1 組
│  ├─ neuron_tile.sv         ニューロン T 個 + step_ctrl。WTA の抑制線を区切る単位
│  ├─ wta_rail.sv            タイル間の抑制線 (link で区切る累積 OR、組み合わせ回路)
│  └─ neuron_array.sv        トップ。タイル NT 個 + wta_rail + 設定書き込み
├─ rtl_ref_parallel_if/     等価性テストの参照モデル (並列演算・漏れなし版)
├─ tb/
│  ├─ membrane_tb.sv         ニューロン単体の 13 シナリオ (重み / 抑制 / 負クランプ / 漏れ k=0,2,15)
│  └─ equiv_tb.sv            直列 LIF 版 vs 並列 IF 版 (104 ニューロン、乱数刺激、全 v と s_out を毎ステップ照合)
├─ scripts/
│  ├─ run_equiv.py           等価性テストの実行 (iverilog)
│  └─ run_sta.ps1            WSL 上の OpenSTA を Windows から呼ぶラッパー
├─ synth/
│  ├─ synth_asic.ys          Yosys 合成スクリプト (階層を残す、abc -D 1000)
│  ├─ abc_constr.f           ABC の駆動セル・負荷
│  ├─ sta_timing.tcl         OpenSTA タイミング (設定系は false path)
│  └─ sta_power.tcl          OpenSTA 電力 (活動率は仮定)
└─ reports/
   └─ synth_sta_summary_2026-10-30.txt   合成・STA 結果と漏れなし版との比較
```

`lib/NangateOpenCellLibrary_typical.lib` は再配布しないため含めていません。合成・STA を再現する場合は各自で入手して `lib/` に置いてください (git 管理外)。

## 動作

1 ステップは `N_IN + 2` サイクルで、タイル内の全ニューロンが同じ指令線で同じ処理をします。

| サイクル | 状態 | 処理 |
|---|---|---|
| 1 〜 N_IN | ACC | `s_in[idx]` が 1 なら `sum += weight[idx]` (符号付き 8 bit → 16 bit に拡張) |
| N_IN + 1 | INH | グループ内に発火があり自分が発火中でなければ `sum -= INH` |
| N_IN + 2 | UPDATE | `v_new = v - (v >> k) + sum` を計算し、`v_new >= v_th` なら発火して `v = 0`、`v_new < 0` なら `v = 0`、それ以外は `v = v_new` |

- 入力も抑制もなく `v = 0` のニューロンは指令線を門で止め、何も動かしません (待機電力を抑える)
- `k` は漏れのシフト量 (全ニューロン共通、4 bit)。`k = 0` で毎ステップ全部抜け、`k = 15` で漏れ 0 (IF と同じ)
- WTA の抑制は `s_out` (1 ステップ保持のレベル) から組み合わせ回路で作るので、発火と同じステップに効きます
- 設定 (重み・タイル境界 `link`・参加 `wta_en`) は `cfg_we / cfg_addr / cfg_data` から 1 本ずつ書きます (アドレス形式は `rtl/neuron_array.sv` 冒頭)

## 既定パラメータ

| 名前 | 値 | 意味 |
|---|---|---|
| WIDTH | 16 | 膜電位のビット幅 (符号付き) |
| W_WIDTH | 8 | 重みのビット幅 (符号付き) |
| N_IN | 8 | 1 ニューロンの入力本数 |
| T / NT | 8 / 8 | 1 タイルのニューロン数 / タイル数 (64 ニューロン) |
| INH | 8 | WTA の抑制量 |
| K_W | 4 | 漏れシフト量 `k` のビット幅 |

## 実行方法

Icarus Verilog 12 (`iverilog` / `vvp`) が PATH にあること。

```powershell
# ニューロン単体のテスト
iverilog -g2012 -s membrane_tb -o membrane.out rtl/membrane.sv rtl/step_ctrl.sv tb/membrane_tb.sv
vvp membrane.out            # 最後に "PASS: all checks passed"

# 直列 LIF 版 と 並列 IF 版 の等価性 (seed 1〜3、各 20000 ステップ)
python scripts/run_equiv.py 1 2 3

# 合成と STA (OSS CAD Suite の yosys、WSL にビルドした OpenSTA。lib/ にライブラリを置いてから)
cd synth
yosys -l synth.log synth_asic.ys
..\scripts\run_sta.ps1 sta_timing.tcl
..\scripts\run_sta.ps1 sta_power.tcl sta_power.log
```

## 合成・STA の結果 (Nangate45 typical、64 ニューロン、配線負荷なし)

漏れを足したことによるコストを、同じ回路の漏れなし版 (IF) と比べたもの。詳細は `reports/`。

| 項目 | 漏れなし (IF) | 漏れあり (LIF) | 比 |
|---|---|---|---|
| 面積 (アレイ全体) | 70,592 µm² | 83,462 µm² | 1.18 |
| 面積 (ニューロン 1 個) | 1,103 µm² | 1,304 µm² | 1.18 |
| 最小クロック周期 | 1.306 ns | 1.373 ns | 1.05 |
| リーク電力 | 1.41 mW | 1.73 mW | 1.23 |
| エネルギー / 1 µs ステップ / ニューロン | 40.7 pJ | 54.1 pJ | 1.33 |

- 増えたのは 16 bit の可変シフタ (MUX 4 段) と減算器だけで、FF は増えていません
- クリティカルパスは WTA の抑制線からニューロン内部 (シフタ → 減算 → 加算 → 判定) に移りました
- 電力は VCD を使わない活動率仮定なので、動的電力は過大側の見積もりです

## 検証の状況

| テスト | 結果 |
|---|---|
| `membrane_tb` 13 シナリオ | PASS |
| 等価性 (k = 15、v_th 固定、seed 1〜3 × 20000 ステップ) | 全 v と s_out で不一致 0 |
| 漏れを効かせた状態での参照モデルとの照合 | 未実施 (単体テストの 4 シナリオのみ) |
