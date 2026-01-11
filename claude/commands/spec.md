---
description: "create spec"
---

Claude Codeを用いた統合型spec-driven developmentを行います。要件定義、設計、実装計画を一つのspecファイルにまとめて作成し、確認後に実装を開始します。

# 準備
- ユーザーがClaude Codeに対して、実行したいタスクの概要を伝える
- タスクの概要から適切な spec 名を考えてそれをslugとします
    - 例：「記事コンポーネントを作成する」→ `create-article-component`
- git branch をデフォルトブランチ（殆どの場合 `main`）にしてremoteからpullして同期
- `git checkout -b {type}/{slug}` としてbranchを作成
  - `type` は `feat`, `fix`, `refactor`, `perf`, `style`, `docs`, `test`, `ci`, `build`, `chore`, `revert` から選択
  - 例： `feat/create-article-component`

# 統合specファイルの作成
- ディレクトリ `.cckiro/specs/{slug}` を作成（例： `.cckiro/specs/create-article-component`）
- `.cckiro/specs/{slug}/spec.md` として統合specファイルを作成
  - ファイルを作成したらそのファイルへのリンクをユーザーに提示せよ
  - specファイルは日本語で作成せよ
  - 図を作る際はAscii Art禁止。mermaid形式にせよ
- このファイルには以下の3つのセクションを含める：

```markdown
# {タスク名} Specification

## 1. 要件定義 (Requirements)

### 概要
[タスクの概要と目的]

### 機能要件
- [要件1]
- [要件2]
- ...

### 非機能要件
- [パフォーマンス要件]
- [セキュリティ要件]
- ...

### 制約事項
- [技術的制約]
- [ビジネス制約]
- ...

## 2. 設計 (Design)

### アーキテクチャ概要
[システムの全体的な設計方針]

### コンポーネント設計
[各コンポーネントの責務と相互作用]

### データフロー
[データの流れと処理]

### インターフェース設計
[API、UI、その他のインターフェース仕様]

### エラーハンドリング
[エラー処理の方針]

## 3. 実装計画 (Implementation Plan)

### 影響を受けるファイル
- 新規作成:
  - [ ] `path/to/new-file1.ext`
  - [ ] `path/to/new-file2.ext`
- 修正:
  - [ ] `path/to/existing-file1.ext`
  - [ ] `path/to/existing-file2.ext`
- 削除:
  - [ ] `path/to/delete-file.ext`

### 実装ステップ
- [ ] **Step 1**: [ステップの説明]
  - 詳細な作業内容
  - 影響するファイル
- [ ] **Step 2**: [ステップの説明]
  - 詳細な作業内容
  - 影響するファイル
- [ ] **Step 3**: [ステップの説明]
  - 詳細な作業内容
  - 影響するファイル
...

### テスト計画
- [ ] ユニットテストの作成/更新
  - テスト内容1
  - テスト内容2
  - ...
- [ ] 統合テストの作成/更新
  - テスト内容1
  - テスト内容2
  - ...

### リリース準備
- [ ] ドキュメントの更新
- [ ] マイグレーション（必要な場合）
```
