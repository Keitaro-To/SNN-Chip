# 論文インデックス

このフォルダは SNN チップ開発で参照する論文を管理する。

## 運用ルール

- **PDF 本体は git に入れない**(`.gitignore` で `*.pdf` を除外)。
  著作権・利用規約上の安全策。各 PC でローカルにダウンロードする。
- **PDF を Markdown に変換した版 (`<short-name>.md`) を git 管理**する。
  本文の要約・引用部分・図表のキャプション・自分のメモを書く。
  別 PC でクローンしただけで論文の中身が読めるようにする。
- **このファイル (`INDEX.md`) には論文 1 本につき 1 エントリ**を追加。
  原典 URL、書誌情報、対応する `.md` ファイル名、扱う章を記録。

## 論文一覧

<!-- ここから下にエントリを追加していく。フォーマットは下のテンプレ参照。 -->

### Spiker+ (本リポジトリの土台論文)

- **正式タイトル**: Spiker+: A Framework for the Generation of Efficient Spiking
  Neural Networks FPGA Accelerators for Inference at the Edge
- **著者 / 年**: A. Carpegna, A. Savino, S. Di Carlo, 2025
- **会議 / 雑誌**: IEEE Transactions on Emerging Topics in Computing, vol. 13,
  no. 3, pp. 784-798, Jul-Sep 2025
- **DOI**: <https://doi.org/10.1109/TETC.2024.3511676>
- **ライセンス**: CC-BY 4.0 (オープンアクセス)
- **対応 Markdown**: [spiker-plus.md](spiker-plus.md)
- **PDF (ローカルのみ)**: `spiker-plus.pdf`
- **公式リポジトリ**: <https://github.com/smilies-polito/Spiker>
- **興味のある章**: §IV (Architecture), §V (Configuration framework), §VI (Results)
- **要点メモ**: 本リポジトリ `rtl/` はこの論文 §IV の自動生成 VHDL を SystemVerilog に
  書き換えたもの。`spiker_pkg` の `mi_*/mc_*/neuron_states_t` は §IV.B〜D の
  3 階層 CU にそのまま対応する。LIF 6 種、reset 2 種、FF-FC / FC-R アーキテクチャ、
  bit-shift / AND / 減算で乗算を消す設計の根拠が全部ここに書いてある。

---

### TEMPLATE: <Short title>

- **正式タイトル**: <Full Title of the Paper>
- **著者 / 年**: <Author1, Author2 et al., Year>
- **会議 / 雑誌**: <Conference / Journal>
- **DOI / arXiv**: <https://arxiv.org/abs/XXXX.XXXXX>
- **対応 Markdown**: [<short-name>.md](<short-name>.md)
- **PDF (ローカルのみ)**: `<short-name>.pdf`
- **興味のある章**: §3 (architecture), §5.2 (energy results)
- **要点メモ**: <自分の理解、引用したい段落、SNN チップ設計に活かせるポイント>

---

## 論文 Markdown のテンプレ

新しい論文を追加するときは [`_template.md`](_template.md) をコピーして
`<short-name>.md` にリネームする。
