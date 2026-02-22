#!/bin/bash
# 共通ライブラリ: 認証・リポジトリ情報取得・GraphQLリクエスト

set -euo pipefail

# GitHub APIトークンを取得する
# 優先順位: GITHUB_TOKEN → GH_TOKEN → gh auth token
get_token() {
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "$GITHUB_TOKEN"
    return
  fi

  if [ -n "${GH_TOKEN:-}" ]; then
    echo "$GH_TOKEN"
    return
  fi

  local token
  token=$(gh auth token 2>/dev/null)
  if [ -n "$token" ]; then
    echo "$token"
    return
  fi

  echo "Error: GitHub token not found. Set GITHUB_TOKEN or GH_TOKEN, or run gh auth login" >&2
  exit 1
}

# git remoteからowner/repoを抽出する
# 出力: "owner repo" (スペース区切り)
get_repo_info() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null)

  if [ -z "$remote_url" ]; then
    echo "Error: No git remote 'origin' found" >&2
    exit 1
  fi

  # SSH形式: git@github.com:owner/repo.git
  # HTTPS形式: https://github.com/owner/repo.git
  local owner repo
  if [[ "$remote_url" =~ git@github\.com:([^/]+)/([^/.]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  elif [[ "$remote_url" =~ github\.com/([^/]+)/([^/.]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  elif [[ "$remote_url" =~ ssh://git@github\.com/([^/]+)/([^/.]+)(\.git)?$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  else
    echo "Error: Cannot parse GitHub owner/repo from remote URL: $remote_url" >&2
    exit 1
  fi

  echo "$owner $repo"
}

# GitHub GraphQL APIにリクエストを送信する
# 引数: $1 = GraphQLクエリ文字列(JSON形式)
# 出力: APIレスポンスのJSON
graphql_request() {
  local query_json="$1"
  local token
  token=$(get_token)

  local response
  response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: bearer $token" \
    -H "Content-Type: application/json" \
    -H "User-Agent: check-pr-comment-skill" \
    https://api.github.com/graphql \
    -d "$query_json")

  local http_code
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" != "200" ]; then
    echo "Error: GraphQL API returned HTTP $http_code" >&2
    echo "$body" >&2
    exit 1
  fi

  # GraphQLエラーチェック
  local has_errors
  has_errors=$(echo "$body" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
print('yes' if 'errors' in data and data['errors'] else 'no')
" 2>/dev/null || echo "unknown")

  if [ "$has_errors" = "yes" ]; then
    echo "Error: GraphQL query returned errors" >&2
    echo "$body" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
for e in data.get('errors', []):
    print(f\"  - {e.get('message', 'unknown error')}\", file=sys.stderr)
" 2>/dev/null
    exit 1
  fi

  echo "$body"
}

# GitHub REST APIにGETリクエストを送信する
# 引数: $1 = APIパス (例: /repos/owner/repo/pulls)
# 出力: APIレスポンスのJSON
rest_get() {
  local path="$1"
  local token
  token=$(get_token)

  local response
  response=$(curl -s -w "\n%{http_code}" \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: bearer $token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "User-Agent: check-pr-comment-skill" \
    "https://api.github.com${path}")

  local http_code
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" != "200" ]; then
    echo "Error: REST API returned HTTP $http_code for $path" >&2
    echo "$body" >&2
    exit 1
  fi

  echo "$body"
}

# 現在のブランチに紐づくPR番号を取得する
# 出力: PR番号 (整数)
find_pr_number() {
  local owner="$1"
  local repo="$2"
  local branch="$3"

  local encoded_head="${owner}:${branch}"
  local path="/repos/${owner}/${repo}/pulls?head=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${encoded_head}', safe=''))")&state=open"

  local response
  response=$(rest_get "$path")

  local pr_number
  pr_number=$(echo "$response" | python3 -c "
import sys, json
prs = json.loads(sys.stdin.read())
if not prs:
    print('')
else:
    print(prs[0]['number'])
" 2>/dev/null)

  if [ -z "$pr_number" ]; then
    echo "Error: No open PR found for branch '$branch'" >&2
    exit 1
  fi

  echo "$pr_number"
}
