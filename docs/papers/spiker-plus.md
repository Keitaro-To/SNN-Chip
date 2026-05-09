# Spiker+: SNN FPGA アクセラレータ生成フレームワーク

> **書誌**: A. Carpegna, A. Savino, S. Di Carlo. *Spiker+: A Framework for the
> Generation of Efficient Spiking Neural Networks FPGA Accelerators for Inference
> at the Edge*. IEEE Transactions on Emerging Topics in Computing, vol. 13, no. 3,
> pp. 784-798, July-September 2025.
> DOI: [10.1109/TETC.2024.3511676](https://doi.org/10.1109/TETC.2024.3511676)
> ライセンス: **CC-BY 4.0** (オープンアクセス)
> ローカル PDF: `spiker-plus.pdf` (git 管理外)
> 公式リポジトリ: <https://github.com/smilies-polito/Spiker>

> **このリポジトリとの関係**: 本リポジトリの `rtl/` 配下は Spiker+ の自動生成 VHDL を
> SystemVerilog に書き換えた成果物。`spiker_pkg.sv`、`barrier`、`multi_cycle`、
> `multi_input_*`、`neuron_*subtractive`、`layer_*`、`network` はすべて本論文 §IV の
> アーキテクチャに 1 対 1 対応する。

---

## 1. 要約 (TL;DR)

- **Spiker+** は **Python 記述 → VHDL 自動生成** で SNN 推論アクセラレータを
  低面積・低消費電力で FPGA 向けに作る EDA フレームワーク。
- LIF ニューロンを **6 種類** 提供 (IF / I-order LIF / II-order LIF) × (hard reset /
  subtractive reset)。
- ネットワークは **FF-FC** (純フィードフォワード全結合) と **FC-R** (層内/層間
  リカレント付き) の 2 種をサポート。
- MNIST で **93.85% accuracy / 780 μs/img / 180 mW / 7,612 logic cells / 18 BRAMs**。
  既存 FPGA SNN アクセラレータと比べて **面積・消費電力で Pareto 最適**。
- SHD と AudioMNIST でも初評価。SHD: 75% / 540 μs / 430 mW、AudioMNIST: 95% / 80 μs / 290 mW。

## 2. 動機・背景

- エッジ推論で SNN を使う利点: 低電力、低レイテンシ、プライバシ。
- 既存 FPGA SNN は「ネットワーク構造をハード回路に焼き付ける」設計が多く、
  **ネットワークと回路の分離が弱い**。
- Spiker+ は「ネットワーク記述 → 自動 RTL 生成」で **モジュール性 + 再構成性 + 高効率**
  を同時に実現する。

## 3. ニューロンモデル (§II.B)

### 3.1 II-order LIF (一番複雑、リカレント時系列向け)

シナプス電流 \(I_{syn}\) と膜電位 \(V_m\) の二段で、α/β は離散時間の指数減衰係数。

\[
I_{syn}[n] = \alpha \cdot I_{syn}[n-1] + W \cdot s_{in}[n]
\]

\[
V_m[n] = (\beta \cdot V_m[n-1] + I_{syn}[n-1]) \cdot r
\]

- **発火条件**: \(s_{out}[n] = 1\) iff \(V_m > V_{th}\)
- **Reset 2 種**:
  - **Hard reset**: \(r = 1 - s_{out}[n-1]\) (発火で膜を 0 に強制)
  - **Subtractive reset**: \(r = 1 - V_{th} / (\beta V_m + I_{syn})\)
    (実装上は \(V_m\) から \(V_{th}\) を引くだけ、これが本リポジトリの選択)

### 3.2 簡略版

- \(\alpha = 0\) で **I-order LIF** (\(I_{syn}\) を経由せず入力スパイクが直接 \(V_m\) に効く)
- \(\beta = 1\) で **IF** (リーク無し、定数記憶)

→ 6 通り (II/I/IF × hard/subtractive) すべてを Spiker+ がライブラリ化。

### 3.3 ハード化のポイント (§IV.D)

掛け算を **AND ゲート + ビットシフト + 引き算** で消す:

| 数式上の演算 | ハード実装 | 備考 |
|-------------|-----------|------|
| \(W \cdot s_{in}\) | **bitwise AND** | スパイクは 1 bit |
| Hard reset \(V \cdot r\) | **MUX** で 0 か V を選択 | バイナリ条件 |
| Subtractive reset | **減算器**で \(V_m - V_{th}\) | 引き算だけ |
| \(\alpha \cdot I_{syn}\), \(\beta \cdot V_m\) | **bit-shift** | \(\alpha = 1 - 2^{-k}\) で近似 |

## 4. アーキテクチャ階層 (§IV.A〜C)

3 階層の Control Unit (CU):

```
Network CU            ← 全体の N_cycles ループを管理
  └── Layer CU        ← 層内の入力スパイクを 1 個ずつニューロンへ配送
        └── Neuron CU ← 膜電位の更新ステップ管理 (LIF FSM)
```

通信は全部 **`start` / `ready` の 2 線ハンドシェイク**。並列同期は AND ゲートで束ねる。

### 4.1 Network CU (§IV.B)

- 1 推論あたり `N_cycles` ステップ進める。
- 全 Layer の `ready` と入出力 IF の `ready` を AND して同期点を作る → これが
  **本リポジトリの `barrier` モジュール**。
- カウンタが `N_cycles` に達したら推論完了 `ready` をアサート。
- → 本リポジトリの **`multi_cycle.sv` + `multi_cycle_cu.sv` + `multi_cycle_datapath.sv`**
  に対応。`mc_states_t` (`MC_RESET`, `MC_IDLE_WAIT`, `MC_INIT`, `MC_UPDATE_WAIT`,
  `MC_NETWORK_UPDATE`) はこの FSM。

### 4.2 Layer CU (§IV.C)

- `N_INPUTS` 個の入力スパイクをカウンタで 1 個ずつ選び、ニューロン群に配る。
- **OR ゲートで「この cycle に少なくとも 1 spike あるか?」を判定**し、ゼロなら
  シーケンシャルなループをスキップ → 電力・時間節約 (sparsity 活用)。
- → 本リポジトリの **`multi_input_16_exc_8_inh.sv`、`multi_input_cu.sv`、
  `multi_input_dp_16_exc_8_inh.sv`** に対応。`mi_states_t` (`MI_RESET`,
  `MI_IDLE_WAIT`, `MI_SAMPLE`, `MI_EXC_UPDATE`, `MI_INH_UPDATE`, ...) はこの FSM。

### 4.3 Neuron CU (§IV.D)

- 膜電位更新の状態機械 (Idle / Init / Excite / Inhibit / Fire / Leak)。
- → 本リポジトリの **`neuron_subtractive.sv` + `neuron_cu_subtractive.sv` +
  `neuron_dp_subtractive.sv`**。`neuron_states_t` (`NS_RESET`, `NS_IDLE`, `NS_INIT`,
  `NS_EXCITE`, `NS_INHIBIT`, `NS_FIRE`, `NS_LEAK`) はこの FSM。

## 5. シナプスとメモリ (§IV.E)

- ニューロン内部パラメータ (Vth, α, β など) → **LUT に格納**。
- シナプス重み → **BRAM に格納** (FPGA 内 SRAM)。並列アクセスが要件。
- 重みが膨大なときは外部 DRAM フォールバックも可能 (latency と引き換え)。
- → 本リポジトリの **`rtl/mem/rom_16x8_exclif1*.sv`、`rom_8x8_inhlif1*.sv`** が
  この BRAM スロット (Xilinx ROM IP の SV ラッパ)。Verilator lint で出ていた
  `addra UNUSEDSIGNAL` は IP の入出力スタブの形を保つための意図的未使用。

## 6. I/O インタフェース (§IV.F)

- 入力スパイクは事前エンコード済み or 内部で rate / population / temporal coding に変換。
- 出力は最終層ニューロンごとの **発火カウンタ** (winner-take-all は外部で判定)。
- すべて `start`/`ready` で同期 → アクセラレータ性能は IF の速度に強く依存。

## 7. Python 設定フレームワーク (§V)

- `netbuilder` → `trainer` (snntorch + BPTT + Surrogate Gradient) → `optimizer`
  (重み量子化、デフォルト 16〜0 bit のグリッドサーチ) → `vhdl_generator` →
  Vivado 用 ROM 設定ファイル + テストベンチ付き VHDL。
- 既存の **SpikExplorer** [9] と組み合わせれば最適アーキテクチャ探索もできる。
- 公式リポジトリ <https://github.com/smilies-polito/Spiker>。

## 8. 主要結果 (§VI)

### 8.1 MNIST (Table II / Fig. 7)

- Spiker+: 93.85% acc / 780 μs / **180 mW / 7,612 logic cells / 18 BRAMs**
- 純粋 SNN (FC) の中で **面積・消費電力で Pareto 最適**。精度では SCNN に劣るが
  狙いがエッジ用低電力なので妥当。

### 8.2 SHD と AudioMNIST (Table III)

| データセット | acc | latency | power | logic cells | BRAMs |
|---|---|---|---|---|---|
| SHD (II-order LIF + FC-R) | 75% | 540 μs | 430 mW | 18,268 | 51 |
| AudioMNIST (40 入力ch) | 95% | 80 μs | 290 mW | 10,124 | 16 |

### 8.3 入力スパース性 vs 性能 (§VI.B, Fig. 9)

- 入力 activity を下げると **latency は下がる** (空 cycle は 1 clk で skip)。
- ただし MNIST/AudioMNIST では **空 cycle のほうが消費電力が高い** ことがある
  (Layer CU が短い周期で状態遷移を繰り返すため switching activity が増える)。
- SHD は BRAM アクセスが支配的でこの傾向は出ない。

### 8.4 量子化 vs 精度 (§VI.C, Fig. 10)

- SNN は量子化に強い: 1 bit 削っても精度低下はわずか。
- bit 幅を 1 削るだけで消費電力に明確な差。
- 並列重み読み出し本数が **回路規模の最大律速** → bit 幅削減で BRAM 節約。

### 8.5 拡張性 (§VI.D, Table IV)

- XC7Z020 で I-order LIF FF-FC なら最大 **1,220 ニューロン** (BRAM 98.5% 使用)。
- XCZU3EG だと 1,900 ニューロン。
- これより大きくしたければ time multiplexing が必要 (今後の拡張ポイント)。

## 9. SNN チップ設計への示唆

このリポジトリ (`rtl/`) はすでに Spiker+ の出力ベースだが、以下の応用余地がある:

- **subtractive vs hard reset の選択**: 現在 subtractive のみ実装 (`neuron_subtractive`)。
  hard reset は MUX 1 個に縮退するのでさらに小さく速い (Fig. 5 の上下の比較)。
- **OR ゲートによる cycle skip**: `multi_input_*` は実装済みだが、cycle skip の効果を
  実機 / シミュで定量化する価値がある (§VI.B のグラフ再現)。
- **bit-shift 近似**: α, β を \(1 - 2^{-k}\) で近似する設計を学習側でも徹底する
  (現在 ROM IP の重み bit 幅は 8 bit、量子化検討の余地)。
- **N_cycles の最適化**: §VI.B 図 8 の通り、入力 activity に応じて N_cycles を減らせれば
  latency が直接縮む。
- **ASIC 化**: §VII の future work で time multiplexing が課題化。本リポジトリで
  OpenLane (Sky130/IHP130) に流すなら同じ問題に直面する。

## 10. 関連論文 (重要な被引用)

- [4] **Carpegna 2022** *Spiker* (前身、IEEE ISVLSI 2022) — 本論文の v1。
- [9] **Padovano 2024** *SpikExplorer* (MDPI Electronics) — Spiker+ と組合せる DSE。
- [5] **Neftci 2019** *Surrogate Gradient* — BPTT で SNN を学習する標準アプローチ。
- [13] **Brette & Gerstner 2005** *AdEx LIF* — LIF モデルの根拠。
- [29] **Frenkel 2022** *ReckOn* — 比較対象 (online learning 付き ASIC)。

## 11. メモ・疑問

- 本リポジトリの `barrier_cu` の状態名 (`MI_RESET`, `MI_IDLE`, `MI_INIT`, `MI_SAMPLE`)
  は Layer CU 用の **`mi_states_t`** をそのまま使っている。本来は別の (短い) 列挙型
  でよさそうだが、`spiker_pkg` を共有するために流用していると思われる。
- §VI.A の `[4]` 旧 Spiker の電力値が「I/O ポートマッピングの誤りで過大評価」と
  注記あり (787 ページ右下)。本リポジトリでも合成時に I/O 配置を要確認。
- VHDL→SV 変換のときに、論文 Fig. 5 のニューロン回路 (subtractive 版だけ) を
  再現していると思われる。fixed/hard reset 版を移植するなら Fig. 5(d)(e)(f) を参照。
