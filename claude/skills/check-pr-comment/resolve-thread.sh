#!/bin/bash
# レビュースレッドをresolveする
# 引数: $1 = スレッドのnode ID (GraphQL ID)
# 出力: 成功/失敗メッセージ

set -euo pipefail

THREAD_ID="${1:?Usage: resolve-thread.sh <thread_node_id>}"

QUERY='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread {
      id
      isResolved
    }
  }
}
'

RESULT=$(gh api graphql \
  -f query="$QUERY" \
  -f threadId="$THREAD_ID" \
  --jq '.data.resolveReviewThread.thread.isResolved')

if [ "$RESULT" = "true" ]; then
  echo "Successfully resolved thread: $THREAD_ID"
else
  echo "Failed to resolve thread: $THREAD_ID" >&2
  exit 1
fi
