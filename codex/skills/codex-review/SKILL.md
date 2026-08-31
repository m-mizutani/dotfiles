---
name: codex-review
description: "Codex の別 process に現在の変更または指定テーマをレビューさせ、指摘を根拠とともに採否判断する。"
---

# Codex セカンドオピニオン

対象が指定されなければ、feature branch では default branch との差分と未コミット変更、default branch では未コミット変更を対象にする。対象と project の `AGENTS.md` を確認してから、独立した review を依頼する。

- 未コミット変更: `codex review --uncommitted <review instructions>`
- branch 差分: `codex review --base <default-branch> <review instructions>`
- 指定した commit: `codex review --commit <sha> <review instructions>`

review instructions には対象、確認したい観点、project instructions を優先すること、`file:line` と根拠を付けることを含める。`codex review` が利用できない、または実行のための承認が得られない場合は、自己レビューへ黙って切り替えず、その状態を報告する。

結果をそのまま採用しない。各指摘について実装・spec・project instructions を確認し、修正、却下、ユーザー判断待ちのいずれかを理由とともに整理する。修正はユーザーが求めた場合だけ行う。
