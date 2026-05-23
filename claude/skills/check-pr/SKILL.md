---
name: check-pr
description: "現在のブランチのPRのレビューコメントとCIステータスを確認し、問題があれば修正する"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, TodoWrite
---

# PRレビューコメント・CI確認・対応スキル

現在のブランチに紐づくPRのレビューコメントとCIの実行結果を確認し、問題があれば修正を行う。

## Part A: CIステータスの確認と修正

### Step A1: CIステータスの取得

以下のコマンドでPRに紐づくCI (GitHub Actions等) のステータスを確認する。

```bash
gh pr checks
```

### Step A2: 失敗したCIの調査

失敗しているチェックがある場合、以下のコマンドで詳細ログを取得する。

```bash
# 失敗したrunのIDを取得
gh run list --branch $(git branch --show-current) --status failure --limit 5 --json databaseId,name,conclusion

# 失敗したrunの詳細ログを確認
gh run view <run_id> --log-failed
```

### Step A3: CI失敗の修正

ログから原因を特定し、修正を行う。修正後、CLAUDE.mdに記載されたチェックコマンド（vet, lint, test等）をローカルで実行して修正が正しいことを確認する。

> **[CRITICAL] 失敗しているCIチェックは、自分の変更が原因かどうかに関わらず、例外なく全て修正すること。**
>
> - 「自分のミスではない」「既存の問題」「flakyテストだから」「mainでも壊れている」等の理由で**絶対にスキップしてはならない**
> - 原因がブランチの変更と無関係に見えても、必ず原因を調査し、このブランチ上で修正してマージ可能な状態にする
> - 環境問題・インフラ問題でローカル修正が不可能な場合のみ、その根拠を明示してユーザーに判断を仰ぐ。安易に「対象外」と判断しない
> - 「赤いCIが1つでも残っている状態」をPR完了とみなさない

### Step A4: CI結果のサマリー

CIチェックの結果をTodoWriteで記録する。全て成功している場合はその旨を記録して Part B に進む。

## Part B: レビューコメントの確認と修正

### Step B1: コメント一覧の取得

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

### Step B2: 対象スレッドの特定とTodoリスト作成

JSONの `threads` 配列から `is_resolved: false` のスレッドのみを抽出し、TodoWriteツールでタスクリストを作成する。各スレッドについてファイルパスと行番号をタスク名に含めること。

### Step B3: 各コメントの精査

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

### Step B4: 妥当性の評価

以下の観点でコメントの妥当性を判断する:

- **正確性**: コードのバグや誤りを指摘しているか
- **セキュリティ**: セキュリティリスクの改善を提案しているか
- **可読性・保守性**: コードの品質向上に寄与するか
- **プロジェクト規約**: プロジェクトの慣例・規約に沿った指摘か
- **実現可能性**: 提案された修正が実現可能で副作用がないか

### Step B5: 修正作業

妥当と判断した場合:
1. コメントで指摘されたファイルパスと行番号を参照し、該当ファイルをReadツールで開く
2. EditまたはWriteツールで修正を適用する
3. CLAUDE.mdに記載されたチェックコマンド（vet, lint, test等）を実行し、修正が既存コードに影響しないことを確認する

### Step B6: Conversationのresolve

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

`<thread_id>` はStep B1で取得したスレッドの `thread_id` フィールドの値を使用する。結果が `true` であればresolve成功。

**注意**: GraphQLクエリは必ず複数行フォーマットで実行すること。1行に圧縮するとパースエラーが発生する場合がある。

### Step B7: 次のコメントへ

TodoWriteで現在のタスクを完了にマークし、次のunresolvedスレッドに対してStep B3から繰り返す。

## Part C: 完了サマリー

全ての確認・修正が完了したら、以下の形式でサマリーを出力する:

```markdown
## PR確認結果

### CIステータス
| チェック名 | ステータス | 対応 |
|-----------|----------|------|
| build | pass | - |
| lint | fail | 修正済み |

### レビューコメント
| スレッド | ファイル | 対応 | 理由 |
|---------|---------|------|------|
| #1 | path/to/file:42 | 修正済み・resolved | [修正理由] |
| #2 | path/to/file:88 | スキップ | [スキップ理由] |
```

スキップしたコメントがある場合は、サマリー出力後にユーザーに確認を取る。ユーザーが「resolveしてよい」と判断したスキップ分についてはStep B6のコマンドを実行してresolveする。

## 注意事項

- **失敗しているCIは自分の変更が原因か否かを問わず全て修正すること。** 既存の壊れ・flaky・無関係を理由にしたスキップは認めない
- コメントの一部だけ読んで判断しないこと。**全文を必ず読み切る**
- 妥当でないと判断した場合は修正せず、理由を記録してスキップする。resolveもしない
- スキップしたコメントは最終的にユーザーの判断を仰ぎ、承認されたらresolveする
- 各スレッドのresolveは1つずつ行うこと。まとめてresolveしない
- GraphQL API呼び出しでTLSエラーが発生した場合、同じコマンドを再試行すること（一時的なエラーの可能性が高い）
- GraphQLクエリは必ず複数行フォーマットで記述すること。1行に圧縮するとパースエラーが発生する
