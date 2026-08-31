---
name: build-review-report
description: "変更内容と検証の到達範囲を、レビュー前に判断できる Markdown レポートへまとめて表示する。"
---

# 変更レビューレポート

レビュー対象を current branch の default branch からの差分と未コミット変更として確定する。変更箇所、周辺コード、spec、テストを読み、次の3点を根拠付きで整理する。

1. 利用者から見た挙動の before/after
2. 変更が必要とする検証
3. 実際に検証済み、弱い、未実施、不要と判断した範囲

`.spec/{branch-slug}/review-report.md` を作成する。branch slug を得られない場合は `.spec/review-report.md` を使う。最初に変更と検証状態を対応付けた小さな図または表を置き、続けて挙動の対比、要求とテストの対応、未充足項目を載せる。テスト名の列挙だけで充足を主張しない。

作成後は `mo <レポートのパス>` で表示する。Claude Code の Artifact は使わず、ファイルの内容を会話中に長く複製しない。
