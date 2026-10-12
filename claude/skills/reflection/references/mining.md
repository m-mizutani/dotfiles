# Session Mining — 操作詳細

セッション解決とフィードバック抽出の具体手順。SKILL.md の Step 1〜2 から参照する。

## セッションの保管場所とパスのエンコード

Claude Code のセッションは `~/.claude/projects/<encoded>/` に JSONL で保存される。`<encoded>` は対象ディレクトリの絶対パスを **`/` と `.` をすべて `-` に置換** したもの。

例: `/Users/mizutani/.ghq/github.com/example-org/example-project`
→ `-Users-mizutani--ghq-github-com-example-org-example-project`
（`/.ghq` の `/`と`.`が連続して `--ghq`、`.com` が `-com` になる点に注意）

## リポジトリ全体（全 worktree）の解決

1. 渡されたパスから **リポジトリルート** を求める。worktree の中（`.../.claude/worktrees/<name>`）なら、その接尾辞を除いた親ディレクトリがルート。判断に迷えば `git -C <path> rev-parse --show-toplevel` の親をたどる。
2. ルートをエンコードして prefix を作る。
3. リポジトリ本体と全 worktree のセッションディレクトリを集める。worktree のセッションは `<encoded-root>--claude-worktrees-<name>` という名前になる。

```bash
ROOT="/Users/mizutani/.ghq/github.com/example-org/example-project"   # Step 1 で求めたルート
ENC=$(awk -v path="$ROOT" 'BEGIN { gsub(/[\/.]/, "-", path); print path }')
PROJ="$HOME/.claude/projects"

# リポジトリ本体 + 全 worktree のセッションディレクトリ
ls -d "$PROJ/$ENC" "$PROJ/$ENC"--claude-worktrees-* 2>/dev/null
```

`<encoded-root>*` のような緩いglobは別リポジトリ（`example-project-extra` 等）を巻き込むので使わない。本体は完全一致、worktree は `--claude-worktrees-*` で限定する。

## 現在のセッションのJSONLを特定する（入力なしモードの補完用）

入力なし（現在セッション）モードでは、会話は既に文脈の中にあるので原則これは不要。文脈が要約で圧縮されて欠けがありそうなときだけ、自分のセッションファイルを開いて補う。

セッションIDは scratchpad ディレクトリのパス末尾に現れる UUID（例: `.../<encoded-cwd>/<session-id>/scratchpad`）。現在の作業ディレクトリ（worktree なら worktree 自身）をエンコードした prefix の下に、その UUID 名の JSONL がある。

```bash
CWD=$(pwd)                                       # worktree の中ならそのパスのまま
ENC=$(awk -v path="$CWD" 'BEGIN { gsub(/[\/.]/, "-", path); print path }')
PROJ="$HOME/.claude/projects"

# 直近に更新された JSONL が現在のセッション（IDが分かっていれば直接指定する方が確実）
ls -t "$PROJ/$ENC"/*.jsonl 2>/dev/null | head -1
```

抽出は本体と同じ「対話を時系列で抽出する jq」を使う。

## 対話（人間＋Claude）を時系列で抽出する jq

反省には Claude が何をしたかが要る。だから人間の発話だけでなく **assistant のテキスト出力も並べて** 抜く。jq は1行ずつ順に処理するので、`type` で role を付けて出すだけで時系列の対話が得られる。

対象は `type=="user"`（人間の発話。content は文字列か配列。配列なら `type=="text"` ブロックが本文）と `type=="assistant"`（content 配列の `type=="text"` がClaudeの提案/結論）。`tool_use` / `tool_result` の本体、`isMeta` / `isSidechain`、`<system-reminder>` `<command-*>` `<local-command-*>` `<task-notification>` ラッパーは無視してよい。

```bash
jq -r '
  select((.type=="user" or .type=="assistant")
         and ((.isMeta // false)|not) and ((.isSidechain // false)|not))
  | (.type|ascii_upcase) as $role
  | .message.content as $c
  | if ($c|type)=="string" then "\n[" + $role + "] " + $c
    else ([ $c[]? | select(.type=="text") | .text ] | join("\n")) as $t
         | if ($t|length) > 0 then "\n[" + $role + "] " + $t else empty end
    end' FILE
```

これで `[USER] ...` と `[ASSISTANT] ...` が交互に並んだ読める対話になる。指摘エピソード（Claudeの提案 → 人間の修正要求）はこの流れから読み取れる。Claudeの思考過程まで踏み込みたい場合だけ、`type=="thinking"` ブロックを追加で覗く（量が多いので原則は text のみ）。

> fish 注意: フィルタは `!=` を **意図的に避けて** `(.x // false) | not`（＝falsyなら通す）で書いている。`!=` を含む jq プログラムは fish のコマンドラインで化けることがあるため。複雑な条件は `.jq` ファイルに書いて `jq -rf filter.jq FILE` で渡すと確実。

## 対話の抽出と教訓の整理のサブエージェント委任（雛形）

全 worktree 分の対話を読むのは重いので、軽量モデル（`sonnet` など）のサブエージェントに委任する。返させるのは生ログではなく **項目ごとに整理した抽出結果** だけ。

```
あなたは Claude Code のセッション JSONL 群を分析し、ソフトウェア設計/実装中に
Claude(ASSISTANT)の誤った提案や行動と、それに対する人間(USER)の指摘を併せて読む。
目的は「Claudeが同じミスを繰り返さないための教訓」を抽出すること。
人間の発話だけを転記しても意味がない。直前にClaudeが何を提案/実装したかを必ず見ること。

対象セッションファイル:
  <解決した JSONL のパスを列挙>

抽出方法（上の jq で [USER]/[ASSISTANT] の対話を時系列で取り出す。python3 は使えない）:
  <上の jq コマンドを貼る>

抽出する対象は次の2種類:
  (1) 指摘エピソード = 人間が修正/軌道修正/修正要求/好みを入れた箇所 +
      その直前にClaudeが提案/実装した内容。単なるタスク依頼は対象外。
  (2) Claude自身の誤りや行き詰まり = 明示的修正要求が無くても、誤った前提・手戻り・
      不要な作業・自己訂正の形跡。

成果物（これだけを返す。生ログは返さない）:
- PART A エピソード一覧: 各件について「Claudeは何をしたか」「人間は何と言ったか
  （引用、日本語可）/ または何が問題だったか」を各一行。
- PART B 教訓の整理: 各エピソードに GENERAL / PROJECT-SPECIFIC のラベルを付け、
  ラベルごとに扱いを変える。似たものはまとめる。
  - GENERAL（どのプロジェクトでも成り立つ）: 具体（このパス・このトークン形式・特定API）
    を除き、「Claudeが本来どう振る舞うべきだったか」を転用可能な一般原則として一文で述べる。
  - PROJECT-SPECIFIC（このコードベース固有）: Claudeがこの固有事情を知らずに不要な作業をしたり、作業が難航したりした箇所。
    こちらは具体的な事実を省かず、「知っていれば不要な作業を避けられた事実」（例: ビルドとテストの実行方法、
    状態の置き場所、生成物の扱い、特定の前提）をそのまま記録する一文にする。
```

返ってきた PART B を SKILL.md Step 3 以降で整理する。
