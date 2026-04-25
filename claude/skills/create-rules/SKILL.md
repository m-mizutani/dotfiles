---
name: create-rules
description: リポジトリのコードベースを分析してClaude Code用のコーディングルール（CLAUDE.md / .claude/rules/）を生成・更新する。「ルールを作りたい」「コーディング規約を設定したい」「CLAUDE.mdを作りたい」「.claude/rulesを整備したい」「このリポジトリのルールを書いて」「プロジェクトのコーディングスタイルを設定して」といったリクエストで使うこと。新規リポジトリの初期設定や、既存ルールの見直し・追加にも対応する。
---

# Create Rules

リポジトリのコードベースを観察し、Claude Codeが従うべきコーディングルールを生成するスキル。

## ルールシステムの概要

Claude Codeには2つのルール配置先がある。用途に応じて使い分ける。

### CLAUDE.md

プロジェクトルートに置く単一ファイル。セッション開始時に必ず読み込まれる。

**置くべきもの：**
- ビルド・テスト・リントの実行コマンド
- 環境構築手順やツールチェインの前提
- プロジェクト全体に適用されるコーディング規約（命名規則、エラーハンドリング方針など）
- アーキテクチャ上の重要な判断事項（「ORMは使わない」「状態管理はXを使う」など）
- コードから読み取れない暗黙のルールや落とし穴

**置くべきでないもの：**
- コードを読めばわかること（ディレクトリ構成の羅列、関数一覧など）
- git historyで追えること
- 特定のドメイン領域にしか関係しない詳細なルール（→ `.claude/rules/` へ）

配置場所のバリエーション：
- `./CLAUDE.md` — プロジェクト共有（gitにコミット）
- `./CLAUDE.local.md` — 個人用（.gitignoreに入れる）
- `~/.claude/CLAUDE.md` — グローバル（全プロジェクト共通）

### .claude/rules/

ドメインごとにルールを分割するためのディレクトリ。中の `.md` ファイルはすべてセッション開始時に読み込まれる。

**使い分けの目安：**
- CLAUDE.md が200行を超えそうなら分割を検討
- テスト、API設計、フロントエンド、DB操作など領域ごとにファイルを分ける
- ファイル名は `testing.md`, `api-conventions.md`, `frontend.md` のように内容を表す名前にする

**書き方：** フロントマターやメタデータは不要。プレーンなMarkdownで書く。

参考ドキュメント：
- https://docs.anthropic.com/en/docs/claude-code/memory
- https://www.anthropic.com/engineering/claude-code-best-practices

## ルール生成の手順

### Step 1: コードベースの観察

以下を調査してリポジトリの特徴を把握する：

1. **言語とフレームワーク** — `go.mod`, `package.json`, `Cargo.toml`, `pyproject.toml` 等の依存定義ファイル
2. **ビルド・テストコマンド** — `Makefile`, `justfile`, `package.json` の scripts, CI設定（`.github/workflows/`）
3. **コードスタイル** — リンター設定（`.golangci.yml`, `.eslintrc`, `ruff.toml` 等）、フォーマッター設定
4. **既存のルールファイル** — `CLAUDE.md`, `.claude/rules/`, `.editorconfig` 等
5. **テストの書き方** — テストファイルの命名規則、使用ライブラリ、モック方針
6. **ディレクトリ構成のパターン** — レイヤー分割の方針、パッケージ構成

### Step 2: ルールの構成を決定

観察結果をもとに、何をCLAUDE.mdに書き、何を `.claude/rules/` に分割するか決める。

**CLAUDE.md に書く内容（目安）：**
- プロジェクトの一行説明
- 主要な開発コマンド（build, test, lint, format）
- 言語バージョンやツールチェインの前提
- プロジェクト全体の基本方針（3〜5項目程度）

**`.claude/rules/` に分けるケース：**
- 特定の言語やフレームワークに固有のルール
- テスト方針の詳細
- API設計規約
- エラーハンドリングのパターン

小〜中規模リポジトリなら CLAUDE.md だけで十分なことも多い。無理に分割しない。

### Step 3: ルールの記述

ルールを書くときの原則：

1. **英語で書く** — ルールの記述は原則として英語を使う。Claudeが最も正確に解釈でき、多言語チームでも共有しやすい
2. **簡潔に、具体的に** — 「きれいなコードを書け」ではなく「エラーは `fmt.Errorf("failed to %s: %w", action, err)` の形式でラップする」のように
3. **コードから読み取れないことだけ** — ファイル構成の説明やライブラリの一覧は不要
4. **なぜそのルールか、を添える** — 「ORMは使わない（パフォーマンスチューニングの柔軟性を確保するため）」のように理由があると判断に使える
5. **コマンドはコピペ可能に** — `go test ./...` のようにそのまま実行できる形で

### Step 4: ユーザーに提示して確認

生成したルールの内容をユーザーに見せ、過不足がないか確認する。ユーザーの修正指示を反映してからファイルに書き込む。

### Step 5: ファイルに書き込む

確認が取れたら CLAUDE.md や `.claude/rules/` にファイルを作成・更新する。既存ファイルがある場合は内容をマージする（上書きしない）。

## ルール記述のテンプレート

### CLAUDE.md の例

```markdown
# プロジェクト名

簡潔な説明文。

## Development

- Build: `make build`
- Test: `make test`
- Lint: `make lint`
- Single test: `go test -run TestName ./path/to/package`

## Coding Rules

- エラーは必ず `%w` でラップして返す
- publicなAPIには godoc コメントを書く
- テストは table-driven test で書く
- 外部APIの呼び出しは interface 経由にする（テスタビリティのため）
```

### .claude/rules/ の例

```markdown
<!-- .claude/rules/testing.md -->
# Testing

- テストライブラリは標準の `testing` パッケージ + `testify/assert` を使う
- テストヘルパーは `t.Helper()` を呼ぶ
- 外部サービスとの結合テストは `//go:build integration` タグで分離する
- テストデータは `testdata/` ディレクトリに置く
```

## 既存ルールの更新

既に CLAUDE.md や `.claude/rules/` が存在する場合：

1. 既存の内容を読み込む
2. コードベースの現状と照らし合わせて、古くなっている箇所や不足を特定する
3. 差分をユーザーに提示する
4. 承認を得てから更新する（既存の内容は壊さない）
