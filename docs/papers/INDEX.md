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
