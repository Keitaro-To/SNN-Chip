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
├─ docs/
│  └─ papers/            # 論文ノート (PDF は git 管理外、Markdown 化版を git 管理)
├─ .cursor/              # Cursor 設定 (rules / skills / agents)
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

## 別 PC でのセットアップ(クローン手順)

### 1. 必要なツールをインストール

| ツール | 必須度 | 入手先 / コマンド |
|---|---|---|
| **git** | 必須 | https://git-scm.com/ |
| **Icarus Verilog 12.0** | 必須(`iverilog` / `vvp`) | http://bleyer.org/icarus/ (Windows インストーラ) |
| **GTKWave** | 推奨(波形閲覧) | Icarus Verilog インストーラに同梱 |
| **WSL Ubuntu + Verilator** | lint を使うなら | `wsl --install Ubuntu` → `sudo apt install -y verilator` |

`iverilog` / `vvp` / `gtkwave` がコマンドラインから呼べる状態にしておく
(インストーラの最後で PATH を通すオプションを ON にするのが楽)。

### 2. リポジトリをクローン

```powershell
git clone https://github.com/<your-id>/<repo-name>.git
cd <repo-name>
```

### 3. 動作確認

```powershell
.\scripts\run.ps1 list             # ターゲット一覧が出れば OK
.\scripts\run.ps1 sim barrier      # 1 つビルド+実行してみる
.\scripts\run.ps1 all              # 全 TB を回す
.\scripts\run.ps1 lint             # (WSL+verilator が入っていれば) 静的解析
```

### 4. (補足) Linux / WSL 内で開発する場合

```bash
sudo apt install -y iverilog gtkwave verilator make
git clone <URL>
cd <repo-name>
make TOP=barrier sim
make all
make lint
```

`scripts/run.ps1` は Windows ネイティブ用、`Makefile` は Linux/WSL/MSYS2 用で
**機能は等価**。どちらの入口から入っても同じビルド結果になる。

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

# Verilator lint (WSL Ubuntu の verilator を使用)
.\scripts\run.ps1 lint                 # rtl_all を lint (top=network)
.\scripts\run.ps1 lint barrier         # 個別ターゲットの lint
.\scripts\run.ps1 lint -Strict         # -Wall を付与し警告も fail にする

# 成果物クリア
.\scripts\run.ps1 clean
```

### make が使える環境 (Linux / WSL / MSYS2)

```bash
make TOP=barrier sim
make TOP=multi_cycle wave
make list
make all
make lint                       # rtl_all を Verilator lint
make LINT_TARGET=barrier lint   # 個別ターゲットを lint
make lint-strict                # -Wall を付与
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

## VHDL → SystemVerilog 変換の命名規約

元の VHDL は識別子の大小文字を区別しないため `reset` と `RESET` が同義になるが、
SystemVerilog は区別する。状態名と信号名・キーワード風の名前が混ざって読みにくく
なるのを避けるため、**パッケージの列挙子は大文字プレフィックス付き** に統一する。

| パッケージ内の型 | プレフィックス | 例 |
| --- | --- | --- |
| `mi_states_t` | `MI_` | `MI_RESET`, `MI_IDLE`, `MI_SAMPLE`, ... |
| `mc_states_t` | `MC_` | `MC_RESET`, `MC_IDLE`, `MC_NETWORK_UPDATE`, ... |
| `neuron_states_t` | `NS_` | `NS_RESET`, `NS_EXCITE`, `NS_FIRE`, ... |

過去の小文字版(`reset`, `idle`, ...) を含む旧パッケージとそれを使う旧モジュールは
`09f97d3` (snapshot) のスナップショットコミットに残っており、必要であれば
`git show 09f97d3:<path>` で参照できる。

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

- **高速シミュ**: Verilator 本体(C++ ラップで 10〜100倍高速、SNN 規模に有用)
- **波形フォーマット**: VCD → FST (GTKWave、サイズ 1/10 以下)
- **CI**: GitHub Actions で `make all` + `make lint-strict` を回す
- **合成バックエンド**:
  - FPGA: Vivado XSim / Yosys+nextpnr
  - ASIC: OpenLane (Sky130/IHP130)

---

## ツール

- [Icarus Verilog 12.0](https://github.com/steveicarus/iverilog) — `iverilog`, `vvp` (シミュレーション)
- [Verilator 5.x](https://www.veripool.org/verilator/) — `--lint-only` で構文/論理チェック (WSL Ubuntu 経由)
- [GTKWave](http://gtkwave.sourceforge.net/) — 波形ビューア (Icarus に同梱)
