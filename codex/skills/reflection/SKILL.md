---
name: reflection
description: "Codex セッションで受けた修正指示と自分の対応を振り返り、再発防止に必要な内容だけを AGENTS.md へ反映する。"
---

# 振り返り

対象が指定されなければ現在の会話を対象にする。過去 session を読む必要がある場合は、Codex が保存する session data の場所とアクセス可否を確認してから対象を限定する。ユーザーの発話だけで結論を出さず、直前の assistant の提案または操作と組にして確認する。

各項目について、何をしたか、なぜ問題だったか、別の repository でも有効かを判断する。既存 instruction で既に防げるなら追加しない。一般的な原則は global instruction の候補として提示するが、利用者の明示的な依頼なしに global file を変更しない。project 固有の事実は対象 repository の `AGENTS.md` に置く候補とする。

更新前に、追加、既存記述の強化、統合、追加不要のいずれかと理由を示し、承認を得る。instruction は英語で書き、具体的な file、command、制約を記録する。
