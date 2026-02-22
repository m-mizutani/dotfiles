#!/bin/bash
# 特定のレビュースレッドの詳細を取得する
# 引数: $1 = スレッドのnode ID (GraphQL ID)
# 出力: JSON形式のスレッド詳細

set -euo pipefail

THREAD_ID="${1:?Usage: get-comment.sh <thread_node_id>}"

QUERY='
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
'

gh api graphql \
  -f query="$QUERY" \
  -f id="$THREAD_ID" \
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
