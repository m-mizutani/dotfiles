---
name: my-code-review
description: "現在の変更または指定範囲を、周辺コード、テスト、spec、AGENTS.md に照らしてレビューし、根拠付きの指摘だけを報告する。"
---

# コードレビュー

レビュー対象を明示されていなければ、feature branch では default branch との merge-base からの差分と未コミット変更、default branch では未コミット変更とする。diff だけで判断せず、変更ファイル全体、呼び出し元・先、同種の既存実装、tests、`AGENTS.md`、関連 spec を読む。

正確性、テストの到達範囲、spec 適合、保守性、公開 interface、error handling、security、documentation のうち変更に関係する観点を確認する。見つけた候補は、出力前に実コードと project instructions で裏付ける。

結果は対象を1行で示した後、`Must-fix`、`Should-fix`、`Consider` の順に整理する。各指摘には `file:line`、問題、発生する結果、具体的な提案、確信度を含める。重大な指摘がなければ、その旨だけを報告する。この skill 自身はコードを変更しない。
