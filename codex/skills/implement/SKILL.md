---
name: implement
description: "承認済み spec または明示された実装依頼を完了まで実装し、検証、レビュー、commit、PR、CI 確認まで進める。"
---

# 実装

開始時に、branch slug に対応する `.spec/{slug}/spec.md` を読む。ユーザーが spec を参照せずに具体的な実装を明示した場合は、その指示を実装対象にする。実装前に `.spec/goal.md` へ完了条件を書き出す。

spec の未完了 task を順に実装し、完了ごとに spec の checkbox を更新する。新しい永続化スキーマ、外部契約、認証フロー、状態の持ち方が必要になる場合は、実装前にユーザーへ変更を示して承認を得る。変更したファイルは個別に `git add <path>` し、`.spec/` は stage しない。

project instructions の verification を実行する。続いて `codex-review` skill を使い、各指摘を実コードで確認する。確信が高い指摘は修正または根拠を示して却下し、判断が必要な指摘はユーザーへ提示する。

すべての完了条件を満たした後に、Semantic Commit 形式の commit、push、PR 作成、CI 確認を行う。いずれかが外部 state を変更するため、実行前に必要な承認を得る。CI が完了しない、または失敗する場合は、原因と未達条件を報告して止める。
