---
name: implement
description: "承認済み spec または明示された実装依頼を完了まで実装し、検証、レビュー、commit、PR、CI 確認まで進める。"
---

# 実装

この skill が、計画、spec の提示、レビュー、または承認依頼より後に明示された場合は、新しい実装指示を優先する。それ以前の同じ権限レベルにある承認待ちを解除し、同じ確認を繰り返さずに完了条件まで進める。上位の instruction、安全上の制約、sandbox や approval の強制、依頼範囲は上書きしない。

開始時に、branch slug に対応する `.spec/{slug}/spec.md` を読む。ユーザーが spec を参照せずに具体的な実装を明示した場合は、その指示を実装対象にする。実装前に `.spec/goal.md` へ完了条件を書き出す。

spec の未完了 task を順に実装し、完了ごとに spec の checkbox を更新する。新しい永続化スキーマ、外部契約、認証フロー、状態の持ち方が必要になる場合は、実装前にユーザーへ変更を示して承認を得る。変更したファイルは個別に `git add <path>` し、`.spec/` は stage しない。

project instructions の verification を実行する。project instructions が自分の変更のレビューを別 process や sub-agent に委譲することを許可している場合は `codex-review` skill を使い、禁止している場合は自分で同じ差分をレビューする。review の実行方法が禁止されていることだけを理由に停止しない。各指摘を実コードで確認し、確信が高い指摘は修正または根拠を示して却下する。結果を変える判断が必要な指摘だけをユーザーへ提示する。

すべての完了条件を満たした後に、Semantic Commit 形式の commit、現在の branch への push、PR 作成、CI 確認を行う。明示的な `$implement` はこれらを含む workflow の実行依頼なので、会話上の確認を工程ごとに繰り返さない。実行環境が tool approval を要求する場合は tool から要求し、承認後は同じ turn で続行する。この承認には destructive action、merge、deploy、別 branch の上書きは含まれない。

進捗報告では turn を終了しない。安全な代替手段で続行できず、完了にユーザーの新しい判断が本当に必要な場合だけ停止する。CI が完了しない、または失敗する場合は原因を調査し、依頼範囲で修正できるものは修正して再実行する。依頼範囲を変える判断が必要な場合は、原因と未達条件を報告して判断を求める。
