---
name: check-pr
description: "現在の branch の pull request について、未解決レビューコメントと CI を確認し、必要な修正と検証を完了する。"
---

# PR 確認

`gh pr checks` で CI を確認し、失敗した check は `gh run list` と `gh run view --log-failed` で原因を確認する。ブランチ上で修正できる失敗は修正し、適用可能な project verification を実行する。環境または外部サービスが原因で修正できない場合は、その証拠を示してユーザーへ判断を求める。

GitHub GraphQL API で未解決 review thread を取得する。各 thread の全コメントと対象コードを読み、指摘が妥当かを project の `AGENTS.md`、spec、実装に照らして判定する。

修正または対応不要の結論が確定した thread を resolve する前に、その変更が external state を更新することをユーザーに知らせ、必要な承認を得る。対応不要の場合も、結論と `file:line` または command output に基づく理由を最終報告へ必ず含める。

完了時は CI の状態、各 thread の対応、未解決事項を表で報告する。
