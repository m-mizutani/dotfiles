---
name: check-pr-comment
description: "現在のブランチのPRに付与されたレビューコメントを確認し、妥当な指摘を修正してresolveする"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
---

# PRレビューコメント確認・対応スキル

現在のブランチに紐づくPRのレビューコメントを全て確認し、妥当な指摘があれば修正を行い、修正後にそのconversationをresolveする。

## 手順

### Step 1: コメント一覧の取得

以下のコマンドを実行して、PRの全レビュースレッドを取得する。

```bash
OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO=$(gh repo view --json name --jq '.name')
PR_NUMBER=$(gh pr view --json number --jq '.number')

gh api graphql -f query='
  query {
    repository(owner: "'"$OWNER"'", name: "'"$REPO"'") {
      pullRequest(number: '"$PR_NUMBER"') {
        title
        url
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            path
            line
            startLine
            comments(first: 50) {
              nodes {
                body
                author { login }
                createdAt
                url
              }
            }
          }
        }
      }
    }
  }
' \
  --jq '{
    pr_number: '"$PR_NUMBER"',
    pr_title: .data.repository.pullRequest.title,
    pr_url: .data.repository.pullRequest.url,
    threads: [.data.repository.pullRequest.reviewThreads.nodes[] | {
      thread_id: .id,
      is_resolved: .isResolved,
      path: .path,
      line: .line,
      start_line: .startLine,
      comments: [.comments.nodes[] | {
        body: .body,
        author: (.author.login // "unknown"),
        created_at: .createdAt,
        url: .url
      }]
    }]
  }'
```

### Step 2: 対象スレッドの特定とTodoリスト作成

JSONの `threads` 配列から `is_resolved: false` のスレッドのみを抽出し、TodoWriteツールでタスクリストを作成する。各スレッドについてファイルパスと行番号をタスク名に含めること。

### Step 3: 各コメントの精査

> **[CRITICAL] コメントは全文を最後まで注意深く読むこと。冒頭など一部だけ読んで判断するのは厳禁。必ずコメントの全文を読み切ってから妥当性を判断すること。**

各unresolvedスレッドについて、以下の手順で処理する:

1. スレッド内の**全コメントの全文**を注意深く読む
2. 必要に応じて、指摘対象のファイルをReadツールで読み込み、該当箇所のコンテキストを理解する
3. コメントの詳細が不足している場合は、以下のコマンドで追加情報を取得する:
   ```bash
   gh api graphql \
     -f id='<thread_id>' \
     -f query='
       query($id: ID!) {
         node(id: $id) {
           ... on PullRequestReviewThread {
             id
             isResolved
             path
             line
             startLine
             diffSide
             comments(first: 100) {
               nodes {
                 body
                 author { login }
                 createdAt
                 url
               }
             }
           }
         }
       }
     ' \
     --jq '{
       thread_id: .data.node.id,
       is_resolved: .data.node.isResolved,
       path: .data.node.path,
       line: .data.node.line,
       start_line: .data.node.startLine,
       diff_side: .data.node.diffSide,
       comments: [.data.node.comments.nodes[] | {
         body: .body,
         author: (.author.login // "unknown"),
         created_at: .createdAt,
         url: .url
       }]
     }'
   ```

### Step 4: 妥当性の評価

以下の観点でコメントの妥当性を判断する:

- **正確性**: コードのバグや誤りを指摘しているか
- **セキュリティ**: セキュリティリスクの改善を提案しているか
- **可読性・保守性**: コードの品質向上に寄与するか
- **プロジェクト規約**: プロジェクトの慣例・規約に沿った指摘か
- **実現可能性**: 提案された修正が実現可能で副作用がないか

### Step 5: 修正作業

妥当と判断した場合:
1. コメントで指摘されたファイルパスと行番号を参照し、該当ファイルをReadツールで開く
2. EditまたはWriteツールで修正を適用する
3. CLAUDE.mdに記載されたチェックコマンド（vet, lint, test等）を実行し、修正が既存コードに影響しないことを確認する

### Step 6: Conversationのresolve

修正完了後、以下のコマンドでconversationをresolveする:

```bash
gh api graphql \
  -f threadId='<thread_id>' \
  -f query='
    mutation($threadId: ID!) {
      resolveReviewThread(input: { threadId: $threadId }) {
        thread {
          id
          isResolved
        }
      }
    }
  ' \
  --jq '.data.resolveReviewThread.thread.isResolved'
```

`<thread_id>` はStep 1で取得したスレッドの `thread_id` フィールドの値を使用する。結果が `true` であればresolve成功。

**注意**: GraphQLクエリは必ず複数行フォーマットで実行すること。1行に圧縮するとパースエラーが発生する場合がある。

### Step 7: 次のコメントへ

TodoWriteで現在のタスクを完了にマークし、次のunresolvedスレッドに対してStep 3から繰り返す。

### Step 8: 完了サマリーとスキップ分の確認

全コメントの処理が完了したら、以下の形式でサマリーを出力する:

```markdown
## PRコメント対応結果

| スレッド | ファイル | 対応 | 理由 |
|---------|---------|------|------|
| #1 | path/to/file:42 | 修正済み・resolved | [修正理由] |
| #2 | path/to/file:88 | スキップ | [スキップ理由] |
```

スキップしたコメントがある場合は、サマリー出力後にユーザーに確認を取る。ユーザーが「resolveしてよい」と判断したスキップ分についてはStep 6のコマンドを実行してresolveする。

## 注意事項

- コメントの一部だけ読んで判断しないこと。**全文を必ず読み切る**
- 妥当でないと判断した場合は修正せず、理由を記録してスキップする。resolveもしない
- スキップしたコメントは最終的にユーザーの判断を仰ぎ、承認されたらresolveする
- 各スレッドのresolveは1つずつ行うこと。まとめてresolveしない
- GraphQL API呼び出しでTLSエラーが発生した場合、同じコマンドを再試行すること（一時的なエラーの可能性が高い）
- GraphQLクエリは必ず複数行フォーマットで記述すること。1行に圧縮するとパースエラーが発生する
