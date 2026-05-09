# `.cursor/` — このリポジトリ専用の Cursor 設定

`git clone` するとこのフォルダごと配布されるため、別 PC でも同じ
ルール / スキルが自動で有効になる。

## 構成

```
.cursor/
├─ rules/        # プロジェクト固有のコーディング規約や手順
│  └─ *.mdc      # 各ルール (YAML フロントマター + Markdown)
├─ skills/       # このリポジトリでだけ使う Agent Skill
│  └─ <skill-name>/SKILL.md
└─ agents/       # カスタムサブエージェント (チャットから /<name> で呼び出す)
   └─ <name>.md  # YAML フロントマター + プロンプト本文
```

## 個人用との使い分け

- **プロジェクト用 (このフォルダ)**: SNN チップ開発に特化した規約・知識。
  `git` で全 PC と共有される。
- **ユーザー用 (`%USERPROFILE%\.cursor\rules\` / `\skills\`)**:
  全リポジトリで共通の個人的な好み。各 PC でローカル管理。

## ルール / スキル / サブエージェントの追加

新しい設定を足したいときは Cursor の組み込みスキルを使うのが楽:

- ルール: 「Cursor のルールを追加して: ...」と頼むと
  `create-rule` スキルが起動して `.cursor/rules/<name>.mdc` を作ってくれる。
- スキル: 「Cursor のスキルを追加して: ...」で
  `create-skill` が `.cursor/skills/<name>/SKILL.md` を作る。
- サブエージェント: `.cursor/agents/<name>.md` を直接作成。
  YAML フロントマターは `name` / `description` / `model` / `readonly` /
  `is_background` の 5 フィールド (詳細は Cursor 公式 docs)。
  チャットから `/<name>` で呼び出せる (例: `/paper-reader STDP の論文を要約して`)。

## 現在登録されているサブエージェント

| 名前 | 役割 |
|------|------|
| `paper-reader` | `docs/papers/` の Markdown 化された論文ノートを参照して文献の質問に答える (readonly) |
