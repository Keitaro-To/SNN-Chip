# プロジェクト固有のスキル置き場

ここには **このリポジトリでだけ使うスキル** を入れる。

## ディレクトリ構造

```
.cursor/skills/
└─ <skill-name>/
   ├─ SKILL.md   # 必須。先頭に YAML フロントマター
   ├─ reference.md  # 任意 (詳しいリファレンス)
   └─ scripts/      # 任意 (補助スクリプト)
```

`SKILL.md` の最低限の形:

```markdown
---
name: <skill-name>
description: <何のスキルか + いつ使うか> (third-person で書く)
---

# <Skill Title>

## Instructions
...
```

## 想定される追加候補

このリポジトリで増やすと便利そうなスキル(まだ未作成):

- `add-rtl-module`: 新しい RTL モジュールを `rtl/<分類>/` に追加し、
  対応する TB と `sim/filelists/<top>.f` を生成する手順を自動化。
- `convert-vhdl-to-sv`: VHDL ソースを SystemVerilog に変換するときの
  チェックリストと命名規約 (`MI_*` / `MC_*` / `NS_*`) の適用。
- `lint-fix`: `verilator --lint-only -Wall` の警告を分類して修正案を出す。

必要になった時点で Cursor の `create-skill` スキルを使って作るのが楽。
