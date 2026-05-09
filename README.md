# SNN チップ開発リポジトリ

Spiker(SNN: Spiking Neural Network)チップの SystemVerilog 実装。
Icarus Verilog (iverilog + vvp) でシミュレーションする構成。

---

## ディレクトリ構成

```
SNN/
├─ rtl/                  # 合成可能な設計コード (.sv)
│  ├─ pkg/               # package, typedef, parameter
│  ├─ common/            # 汎用部品 (mux, reg, cnt, cmp, shifter, ...)
│  ├─ mem/               # ROM 等のメモリ
│  ├─ sync/              # 同期/制御 (barrier, multi_cycle)
│  ├─ neuron/            # ニューロン (subtractive LIF)
│  ├─ network/           # 多入力・レイヤ
│  └─ top/               # トップレベル (network)
│
├─ tb/                   # テストベンチ (合成対象外)
│  ├─ unit/              # 各モジュール単体
│  └─ system/            # トップレベル結合
│
├─ sim/                  # シミュレーション領域
│  ├─ filelists/         # コンパイル対象を列挙する .f ファイル
│  ├─ build/             # vvp バイナリ等 (gitignore)
│  └─ waves/             # VCD/FST (gitignore)
│
├─ scripts/              # ビルドランナー (run.ps1 等)
├─ docs/                 # 仕様書、状態遷移図
├─ legacy/               # 重複/不整合のため隔離 (要レビュー)
│
├─ Makefile              # GNU make 用 (任意)
├─ .gitignore
└─ README.md
```

### 設計原則

- **`rtl/` と `tb/` を必ず分離**:合成対象とそうでないものを混ぜない。
- **ソースの場所はツールに教える**:テストベンチでパスを書かないこと。
  `sim/filelists/<TOP>.f` にコンパイル対象を列挙し、`-f` で渡す。
- **ビルド成果物は Git に載せない**:`sim/build/`, `sim/waves/` は `.gitignore`。

---

## ビルド・シミュレーション

### Windows (PowerShell, make 不要)

```powershell
# 利用可能ターゲット一覧
.\scripts\run.ps1 list

# 個別実行
.\scripts\run.ps1 sim   barrier        # barrier_tb をビルド+実行
.\scripts\run.ps1 wave  multi_cycle    # 実行して GTKWave を開く
.\scripts\run.ps1 build network        # ビルドだけ

# 全 TB を順番に実行
.\scripts\run.ps1 all

# 成果物クリア
.\scripts\run.ps1 clean
```

### make が使える環境 (Linux / WSL / MSYS2)

```bash
make TOP=barrier sim
make TOP=multi_cycle wave
make list
make all
make clean
```

---

## ファイルリスト (`sim/filelists/*.f`)

`.f` は iverilog にコンパイル対象とオプションを渡すテキストファイル。
ファイル分割で参照が壊れる問題は **すべてここで吸収** する。

- `common.f` … 全ターゲットで必要な共通設定 + パッケージ
- `rtl_all.f` … 全 RTL を列挙(system テスト・lint で使用)
- `<top>.f` … 各 TB 用。`-f common.f` で共通分を取り込む

新しい TB を追加するときは、`sim/filelists/<TOP>.f` を新設するだけで OK。

実行時の CWD は `sim/build/` のため、`.f` 内のパスは `../../rtl/...` 形式で書く。

---

## 新しいモジュールの追加手順

1. `rtl/<分類>/<module>.sv` に設計を書く。
2. `tb/unit/<module>_tb.sv` にテストベンチを書く。
   波形を出すなら `$dumpfile("<top>_tb.vcd"); $dumpvars(0, <top>_tb);` を入れる。
3. `sim/filelists/<top>.f` を作成 (既存をコピーするのが速い)。
   - 必要な依存ファイルを上から順に列挙する。
   - 一番下に TB を置く。
4. `.\scripts\run.ps1 sim <top>` で動作確認。

---

## `legacy/` フォルダについて

整理時点で **使用すべきでないファイル** を隔離した置き場所。compile されないので
ビルドには影響しない。レビューしてから削除/統合すること。

| ファイル | 内容 | 推奨対応 |
| --- | --- | --- |
| `spiker_pkg_legacy.sv` | 旧版 `spiker_pkg`(`reset/idle/...` 小文字)。現在の `rtl/pkg/spiker_pkg.sv` (`MI_*`/`MC_*`/`NS_*` 大文字) と衝突する。 | 確認の上、削除 |
| `barrier_cu_dup.sv` | 旧 `barrier_cu_tb.sv`。実体は `barrier_cu` 設計の重複コピー(TB ではない)。 | 削除 |
| `mux_16to1_dup.sv` | 旧 `mux_16to1_tb.sv`。実体は `mux_16to1` 設計の重複コピー。 | 削除 |
| `mux_8to1_dup.sv`  | 旧 `mux_8to1_tb.sv`。実体は `mux_8to1` 設計の重複コピー。 | 削除 |

---

## 主な不整合・既知の問題

整理時点で観察された注意点:

- 元の `multi_cycle_dapapath.sv` (typo) を `multi_cycle_datapath.sv` に改名済み。
  内部の module 名と `multi_cycle.sv` 内のインスタンス参照も修正済み。
- 多くの `_tb.sv` ファイルが実際には TB ではなく「設計の重複コピー」だった
  (`legacy/` に隔離済み、上表参照)。
- `network_tb.sv` の `$dumpfile("network_tb.vcd")` は相対パス。実行は `sim/build/`
  からなので、生成された VCD は `run.ps1` / `Makefile` が `sim/waves/` に移動する。

---

## 将来の拡張ポイント

- **lint**: `verilator --lint-only -f sim/filelists/rtl_all.f` を CI に追加
- **高速シミュ**: Verilator(C++ ラップで 10〜100倍高速、SNN 規模に有用)
- **波形フォーマット**: VCD → FST (GTKWave、サイズ 1/10 以下)
- **CI**: GitHub Actions で `make all` を回す
- **合成バックエンド**:
  - FPGA: Vivado XSim / Yosys+nextpnr
  - ASIC: OpenLane (Sky130/IHP130)

---

## ツール

- [Icarus Verilog 12.0](https://github.com/steveicarus/iverilog) — `iverilog`, `vvp`
- [GTKWave](http://gtkwave.sourceforge.net/) — 波形ビューア (Icarus に同梱)
