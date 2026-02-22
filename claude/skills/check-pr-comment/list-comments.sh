#!/bin/bash
# PRの全レビュースレッド一覧を取得する
# 出力: JSON形式のスレッド一覧

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

read -r OWNER REPO <<< "$(get_repo_info)"
BRANCH=$(git rev-parse --abbrev-ref HEAD)

PR_NUMBER=$(find_pr_number "$OWNER" "$REPO" "$BRANCH")
echo "PR #${PR_NUMBER} found for branch '${BRANCH}'" >&2

QUERY='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
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
'

gh api graphql \
  -f query="$QUERY" \
  -F owner="$OWNER" \
  -F repo="$REPO" \
  -F pr="$PR_NUMBER" \
  --jq '{
    pr_title: .data.repository.pullRequest.title,
    pr_url: .data.repository.pullRequest.url,
    pr_number: '"$PR_NUMBER"',
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
