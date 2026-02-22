#!/bin/bash
# 共通ライブラリ: リポジトリ情報取得
# 認証は gh が自動処理する

set -euo pipefail

# git remoteからowner/repoを抽出する
# 出力: "owner repo" (スペース区切り)
get_repo_info() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null)

  if [ -z "$remote_url" ]; then
    echo "Error: No git remote 'origin' found" >&2
    exit 1
  fi

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

# 現在のブランチに紐づくPR番号を取得する
# 出力: PR番号 (整数)
find_pr_number() {
  local owner="$1"
  local repo="$2"
  local branch="$3"

  local pr_number
  pr_number=$(gh api "/repos/${owner}/${repo}/pulls" \
    -f head="${owner}:${branch}" \
    -f state=open \
    --jq '.[0].number // empty')

  if [ -z "$pr_number" ]; then
    echo "Error: No open PR found for branch '$branch'" >&2
    exit 1
  fi

  echo "$pr_number"
}
