#!/bin/bash
# レビュースレッドをresolveする
# 引数: $1 = スレッドのnode ID (GraphQL ID)
# 出力: 成功/失敗メッセージ

set -euo pipefail

THREAD_ID="${1:?Usage: resolve-thread.sh <thread_node_id>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# GraphQL mutationでスレッドをresolve
QUERY=$(python3 -c "
import json
query = '''
mutation(\$threadId: ID!) {
  resolveReviewThread(input: { threadId: \$threadId }) {
    thread {
      id
      isResolved
    }
  }
}
'''
print(json.dumps({
    'query': query,
    'variables': {
        'threadId': '$THREAD_ID'
    }
}))
")

RESPONSE=$(graphql_request "$QUERY")

# 結果確認
IS_RESOLVED=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
thread = data['data']['resolveReviewThread']['thread']
print(thread['isResolved'])
" 2>/dev/null)

if [ "$IS_RESOLVED" = "True" ]; then
  echo "Successfully resolved thread: $THREAD_ID"
else
  echo "Failed to resolve thread: $THREAD_ID" >&2
  echo "$RESPONSE" >&2
  exit 1
fi
