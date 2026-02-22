#!/bin/bash
# 特定のレビュースレッドの詳細を取得する
# 引数: $1 = スレッドのnode ID (GraphQL ID)
# 出力: JSON形式のスレッド詳細

set -euo pipefail

THREAD_ID="${1:?Usage: get-comment.sh <thread_node_id>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# GraphQLでスレッド詳細を取得
QUERY=$(python3 -c "
import json
query = '''
query(\$id: ID!) {
  node(id: \$id) {
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
          author {
            login
          }
          createdAt
          url
        }
      }
    }
  }
}
'''
print(json.dumps({
    'query': query,
    'variables': {
        'id': '$THREAD_ID'
    }
}))
")

RESPONSE=$(graphql_request "$QUERY")

# 整形して出力
echo "$RESPONSE" | python3 -c "
import sys, json

data = json.loads(sys.stdin.read())
node = data['data']['node']

if not node:
    print(json.dumps({'error': 'Thread not found', 'thread_id': '$THREAD_ID'}))
    sys.exit(1)

result = {
    'thread_id': node['id'],
    'is_resolved': node['isResolved'],
    'path': node.get('path', ''),
    'line': node.get('line'),
    'start_line': node.get('startLine'),
    'diff_side': node.get('diffSide', ''),
    'comments': []
}

for c in node['comments']['nodes']:
    result['comments'].append({
        'body': c['body'],
        'author': c['author']['login'] if c.get('author') else 'unknown',
        'created_at': c['createdAt'],
        'url': c.get('url', '')
    })

print(json.dumps(result, indent=2, ensure_ascii=False))
"
