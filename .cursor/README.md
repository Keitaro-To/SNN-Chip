# `.cursor/` — このリポジトリ専用の Cursor 設定

`git clone` するとこのフォルダごと配布されるため、別 PC でも同じ
ルール / スキルが自動で有効になる。

## 構成

```
.cursor/
├─ rules/        # プロジェクト固有のコーディング規約や手順
│  └─ *.mdc      # 各ルール (YAML フロントマター + Markdown)
└─ skills/       # このリポジトリでだけ使う Agent Skill
   └─ <skill-name>/SKILL.md
```

## 個人用との使い分け

- **プロジェクト用 (このフォルダ)**: SNN チップ開発に特化した規約・知識。
  `git` で全 PC と共有される。
- **ユーザー用 (`%USERPROFILE%\.cursor\rules\` / `\skills\`)**:
  全リポジトリで共通の個人的な好み。各 PC でローカル管理。

## ルール / スキルの追加

新しいルールやスキルを足したいときは Cursor の組み込みスキルを使うのが楽:

- ルール: 「Cursor のルールを追加して: ...」と頼むと
  `create-rule` スキルが起動して `.cursor/rules/<name>.mdc` を作ってくれる。
- スキル: 「Cursor のスキルを追加して: ...」で
  `create-skill` が `.cursor/skills/<name>/SKILL.md` を作る。
