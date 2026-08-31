---
name: refine-rules
description: "リポジトリを観察し、Codex が読む AGENTS.md を作成または更新して、実際の開発コマンドと project 固有の規約を記録する。"
---

# AGENTS.md の整備

言語、依存関係、build/test/lint command、CI、formatter、既存の `AGENTS.md`、test の書き方を確認する。コードから自明な directory 一覧や identifier 一覧は instruction に書かない。

壊れた build、CI の不足、secret を含む `.gitignore` の漏れ、既存 instruction と実装の不一致を見つけた場合は、rule を書く前に根拠を示す。修正が必要な場合はユーザーの承認を得る。

repository root には全体の `AGENTS.md` を置き、より狭い領域に異なる規約がある場合だけ nested `AGENTS.md` を置く。内容は実行可能な verification command、コードから分からない制約、設計上の重要な判断、変更時に必要な documentation を英語で簡潔に記録する。

既存 file を更新する場合は、差分を示してから書き込む。global `~/.codex/AGENTS.md` は利用者が明示的に求めない限り変更しない。
