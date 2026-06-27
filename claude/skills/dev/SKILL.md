---
name: dev
description: "spec-driven developmentを開始・継続する。新しい開発タスク、specの作成、実装の開始・再開など、開発に関わるあらゆるフェーズで使用せよ。ユーザーが開発タスクについて言及したとき、feature branchでの作業を始めるとき、実装を進めたいときに必ずこのスキルを使うこと。"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch, Artifact, Skill
---

# spec-driven development 統合ワークフロー

現在の状況を自動判定し、適切なフェーズから開発を開始・継続する。

# 状況判定

まず以下の情報を収集し、現在のフェーズを判定せよ：

1. `git branch --show-current` で現在のブランチ名を取得
2. ブランチ名からslugを抽出（slash以降。例: `feat/create-article-component` → `create-article-component`）
3. `.spec/{slug}/spec.html` の存在確認
4. specファイルが存在する場合、タスクの進捗状況（`class="task done"` / `class="task todo"`）を確認

## フェーズ判定ルール

| 条件 | フェーズ |
|------|---------|
| main/masterブランチにいる & specなし | **Phase 1: 計画開始** |
| feature branchにいる & specなし | **Phase 1: 計画開始**（ブランチは既存を使う） |
| feature branchにいる & specあり & タスク未着手 | **Phase 2: 実装開始** |
| feature branchにいる & specあり & タスク一部完了 | **Phase 3: 実装再開** |
| feature branchにいる & specあり & タスク全完了 | **Phase 4: 仕上げ** |

判定結果をユーザーに伝えてから、該当フェーズの作業を開始せよ。

> **⚠️ 絶対ルール: specファイルが存在しない場合、Phase 1（計画開始）以外のフェーズに進んではならない。どんな場合でも、まず spec を作成し、ユーザーの承認を得ること。Auto modeであっても、spec承認前に実装を開始することは禁止。**

---

# Phase 1: 計画開始

ユーザーから実行したいタスクの概要を聞き、spec作成から始める。

## ブランチ準備
- タスク概要から適切なslugを考える（例：「記事コンポーネントを作成する」→ `create-article-component`）
- main/masterにいる場合：
  - remoteからpullして同期
  - `git checkout -b {type}/{slug}` でブランチ作成
  - `type` は `feat`, `fix`, `refactor`, `perf`, `style`, `docs`, `test`, `ci`, `build`, `chore`, `revert` から選択
- 既にfeature branchにいる場合：そのブランチをそのまま使う

## 統合specファイルの作成

specはMarkdownではなく **HTML** で作成し、`Artifact` ツールでブラウザに公開してレビューに供する。

- `.spec/{slug}/` ディレクトリを作成
- specの実体（アップロード用HTML）は **`.spec/{slug}/spec.html`** に配置する。`Artifact` ツールにはこのファイルパスを渡す
- HTMLを書く前に **必ず `artifact-design` skill を読み込む**（`Artifact` ツールの前提）。デザイン投資の度合いはそのガイドに従う
- **`spec.html` はページの中身（コンテンツ断片）だけを書く。** `<!doctype>` / `<html>` / `<head>` / `<body>` タグは書かない（Artifact公開時に自動でラップされ、最小限のCSSリセットも適用される）。`<style>` と本文要素を直書きする
- 本文は日本語で記述する
- **図は inline SVG または HTML+CSS（box-and-arrow等）で表現する。** mermaid は Artifact の厳格なCSP（外部スクリプト/CDNを遮断）下で描画できないため使用禁止。ASCII Art も引き続き禁止
- **進捗チェックボックスは `<li class="task todo">` / `<li class="task done">` で表現する。** 下記テンプレートの `<style>` が `☐` / `☑` を描画する。実装時はこの `todo` ↔ `done` のクラスを書き換えて進捗を管理する（grepしやすく編集も容易）

以下のテンプレートを `.spec/{slug}/spec.html` の出発点とする（`{タスク名}` 等のプレースホルダは埋める）:

```html
<style>
  .spec { max-width: 56rem; margin: 0 auto; padding: 1rem; line-height: 1.7; }
  .spec h1 { border-bottom: 2px solid currentColor; padding-bottom: .3rem; }
  .spec h2 { margin-top: 2.2rem; border-bottom: 1px solid #8884; padding-bottom: .2rem; }
  .spec .note { border-left: 4px solid #8888; padding: .4rem .9rem; background: #8881; border-radius: 4px; }
  .spec ul.tasks { list-style: none; padding-left: 1.2rem; }
  .spec li.task { position: relative; }
  .spec li.task::before { position: absolute; left: -1.2rem; }
  .spec li.task.todo::before { content: "☐"; }
  .spec li.task.done::before { content: "☑"; }
  .spec li.task.done { opacity: .65; }
  .spec figure { margin: 1rem 0; text-align: center; }
  .spec code { background: #8882; padding: .1rem .3rem; border-radius: 3px; }
</style>
<article class="spec">
  <h1>{タスク名} Specification</h1>

  <h2>1. 要件定義 (Requirements)</h2>
  <h3>概要</h3>
  <p>[タスクの概要と目的]</p>
  <h3>機能要件</h3>
  <ul><li>[要件1]</li><li>[要件2]</li></ul>
  <h3>非機能要件</h3>
  <ul><li>[パフォーマンス要件]</li><li>[セキュリティ要件]</li></ul>
  <h3>制約事項</h3>
  <ul><li>[技術的制約]</li><li>[ビジネス制約]</li></ul>

  <h2>2. 設計 (Design)</h2>
  <h3>アーキテクチャ概要</h3>
  <p>[システムの全体的な設計方針]</p>
  <figure>
    <!-- 図は inline SVG または HTML+CSS で描く（mermaid/ASCII Art禁止） -->
    <svg viewBox="0 0 100 30" role="img" aria-label="[図の説明]"><!-- ... --></svg>
    <figcaption>[図の説明]</figcaption>
  </figure>
  <h3>コンポーネント設計</h3>
  <p>[各コンポーネントの責務と相互作用]</p>
  <h3>データフロー</h3>
  <p>[データの流れと処理]</p>

  <h3>外的インターフェース (External Interfaces)</h3>
  <p class="note">このセクションは特に詳細に記述すること。外部から観測・利用される境界は、後から変更すると影響範囲が大きいため、設計段階で具体的に確定させる。以下のうち該当するものはすべて、名前・型・デフォルト値・必須/任意・後方互換性への影響まで明記する。該当がない項目は「なし」と明示する。</p>
  <ul>
    <li><strong>API / エンドポイント</strong>: 追加・変更するエンドポイント、リクエスト/レスポンスのスキーマ、ステータスコード、認証方式</li>
    <li><strong>関数・メソッド・型シグネチャ</strong>: 公開（exported）される関数・メソッド・構造体・インターフェースのシグネチャと責務</li>
    <li><strong>設定 (Configuration)</strong>: 追加・変更する設定項目、設定ファイルのキー、デフォルト値、許容値の範囲</li>
    <li><strong>環境変数 (Environment Variables)</strong>: 追加・変更・削除する環境変数名、用途、デフォルト値、必須かどうか</li>
    <li><strong>CLIフラグ・引数</strong>: 追加・変更するコマンドラインフラグ、引数、サブコマンド</li>
    <li><strong>データスキーマ / マイグレーション</strong>: DBスキーマ、メッセージフォーマット、永続化フォーマットの変更</li>
    <li><strong>外部連携 / 権限</strong>: 外部サービス連携、必要なOAuthスコープ・IAM権限、Webhook など</li>
  </ul>

  <h3>UI / その他のインターフェース</h3>
  <p>[UIの画面・操作、上記に当てはまらないインターフェース仕様]</p>
  <h3>エラーハンドリング</h3>
  <p>[エラー処理の方針]</p>

  <h2>3. 実装計画 (Implementation Plan)</h2>
  <h3>影響を受けるファイル</h3>
  <p>新規作成:</p>
  <ul class="tasks">
    <li class="task todo"><code>path/to/new-file1.ext</code></li>
    <li class="task todo"><code>path/to/new-file2.ext</code></li>
  </ul>
  <p>修正:</p>
  <ul class="tasks">
    <li class="task todo"><code>path/to/existing-file1.ext</code></li>
  </ul>
  <p>削除:</p>
  <ul class="tasks">
    <li class="task todo"><code>path/to/delete-file.ext</code></li>
  </ul>

  <h3>実装ステップ</h3>
  <ul class="tasks">
    <li class="task todo"><strong>Step 1</strong>: [ステップの説明]（詳細な作業内容 / 影響するファイル）</li>
    <li class="task todo"><strong>Step 2</strong>: [ステップの説明]（詳細な作業内容 / 影響するファイル）</li>
    <li class="task todo"><strong>Step 3</strong>: [ステップの説明]（詳細な作業内容 / 影響するファイル）</li>
  </ul>

  <h3>テスト計画</h3>
  <ul class="tasks">
    <li class="task todo">ユニットテストの作成/更新（テスト内容1 / テスト内容2）</li>
    <li class="task todo">統合テストの作成/更新（テスト内容1 / テスト内容2）</li>
  </ul>

  <h3>リリース準備</h3>
  <ul class="tasks">
    <li class="task todo">ドキュメントの更新（特に「外的インターフェース」の変更点 — API・設定・環境変数など — を反映する）</li>
    <li class="task todo">マイグレーション（必要な場合）</li>
  </ul>
</article>
```

## spec作成後の必須手順

> **⚠️ 重要: 以下の手順を必ず両方とも実行せよ。省略は禁止。**

1. **`Artifact` ツールで公開する（必須）**: spec作成（`.spec/{slug}/spec.html` の書き込み）が完了したら、`Artifact` ツールに `file_path` として `.spec/{slug}/spec.html` を渡してブラウザに公開する。`title` はタスク名のspec、`favicon` は `📋` 等を指定する。返ってきたArtifactのURLをユーザーに提示せよ。specを修正したら **同じ `file_path` で再度 `Artifact` を呼び**、同一URLへ再デプロイする（URLを変えない）。
2. **ユーザーにレビューを依頼し、ここで必ず停止する（必須）**: Artifactを提示した状態でレビューを依頼し、**ユーザーから明示的な承認を得るまで Phase 2 に進んではならない。** Auto modeであっても、承認なしに実装を開始することは絶対に禁止。ユーザーが「OK」「進めて」「LGTM」等の承認を返すまで待つこと。

---

# Phase 2: 実装開始

specファイルに基づいて実装を開始する。

## コンテキストの整理
- 実装開始前に `/compact` を実行してコンテキストを圧縮せよ。Phase 1での議論やspec作成過程の詳細はspecファイルに集約されているため、コンテキストウィンドウを実装作業のために確保する

## specの読み込み
- ファイルパスが引数で与えられた場合はそのパス、なければブランチ名のslugから `.spec/{slug}/spec.html` をspecとして読み込む
- specの内容（要件・設計・実装計画）を把握してから実装に着手する

## 調査・リサーチ
- 実装中にライブラリのAPIやフレームワークの仕様を確認する必要がある場合、WebFetchやWebSearchを使って公式ドキュメントなどを参照せよ
- 不明な仕様や使い方があれば、推測で実装せず調べてから進める

## 実装の進め方
- 実装計画のステップに沿って順に進める
- 完了した作業や編集が終わったファイルは、対応する `<li class="task todo">` を `<li class="task done">` に書き換えて進捗を記録しながら進める（最後にまとめてではなく、都度実施）
- 進捗を更新すると同時にspecの内容を見直し、実装すべき内容や方向性を確認する
- specを書き換えたら **同じ `file_path` で `Artifact` ツールを呼び直し**、公開中のArtifactを最新状態に再デプロイする（URLは変わらない）
- 実装中に追加の指示があった場合は `spec.html` も更新する
- 実装に支障をきたす問題が発生しない限り、最後まで完了させよ。途中で止まるな
- `// TODO` や `// FIXME`、仮実装、スタブなどを残すな。すべての機能を完全に実装し切ること

## git add
- ファイルを変更・作成したら都度 `git add` せよ。実装完了時にまとめてではなく、変更のたびに実施する
- **`git add .` や `git add -A` のような一括追加は禁止。** 必ず `git add <ファイルパス>` で対象ファイルを明示的に指定すること
- **specファイル（`.spec/` 以下）は `git add` するな。** specはあくまで作業用ドキュメントであり、コミット対象に含めない

---

# Phase 3: 実装再開

途中まで進んでいる実装を継続する。

- `spec.html` を読み込み、`task todo` / `task done` の状態から進捗を把握する
- 未完了（`task todo`）のステップの最初から実装を再開する
- Phase 2と同じルールに従って進める（進捗更新のたびに `Artifact` を同一 `file_path` で再デプロイすることを含む）

---

# Phase 4: 仕上げ

実装計画のタスク（`<li class="task ...">`）がすべて `done` になっている状態。

- specを最終確認し、漏れがないか点検する（必要なら `Artifact` を再デプロイして最新状態を反映する）
- テスト計画に基づいてテストが通ることを確認する
- ユーザーに完了報告する
