#!/bin/bash
# PRの全レビュースレッド一覧を取得する
# 出力: JSON形式のスレッド一覧

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

# リポジトリ情報取得
read -r OWNER REPO <<< "$(get_repo_info)"
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# PR番号取得
PR_NUMBER=$(find_pr_number "$OWNER" "$REPO" "$BRANCH")
echo "PR #${PR_NUMBER} found for branch '${BRANCH}'" >&2

# GraphQLでレビュースレッド一覧を取得
QUERY=$(python3 -c "
import json
query = '''
query(\$owner: String!, \$repo: String!, \$pr: Int!) {
  repository(owner: \$owner, name: \$repo) {
    pullRequest(number: \$pr) {
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
  }
}
'''
print(json.dumps({
    'query': query,
    'variables': {
        'owner': '$OWNER',
        'repo': '$REPO',
        'pr': $PR_NUMBER
    }
}))
")

RESPONSE=$(graphql_request "$QUERY")

# 整形して出力
echo "$RESPONSE" | python3 -c "
import sys, json

data = json.loads(sys.stdin.read())
pr = data['data']['repository']['pullRequest']
threads = pr['reviewThreads']['nodes']

result = {
    'pr_title': pr['title'],
    'pr_url': pr['url'],
    'pr_number': $PR_NUMBER,
    'threads': []
}

for t in threads:
    thread = {
        'thread_id': t['id'],
        'is_resolved': t['isResolved'],
        'path': t.get('path', ''),
        'line': t.get('line'),
        'start_line': t.get('startLine'),
        'comments': []
    }
    for c in t['comments']['nodes']:
        thread['comments'].append({
            'body': c['body'],
            'author': c['author']['login'] if c.get('author') else 'unknown',
            'created_at': c['createdAt'],
            'url': c.get('url', '')
        })
    result['threads'].append(thread)

print(json.dumps(result, indent=2, ensure_ascii=False))
"
