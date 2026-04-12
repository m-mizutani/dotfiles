---
name: difit
description: difitコマンドでGitのdiffをブラウザのGitHub風UIで表示する。コードレビューや差分確認時に使用。
user_invocable: true
---

# difit

会話のコンテキストに応じて `difit` コマンドを実行し、Gitの差分をブラウザで表示する。

## 基本方針

- 基本的には、現在作業しているgitリポジトリの変更差分を表示するために起動する
- ブラウザを自動で開く（`--no-open` は付けない）

## 手順

1. ユーザーの引数や会話のコンテキストから、表示したい差分の対象を判断する:
   - 引数なし・特に指定がない場合: `difit working --include-untracked` (現在の作業ツリーの変更を表示)
   - コミット指定: `difit HEAD~3` など
   - ブランチ比較: `difit main feature-branch` など
   - ステージ済み: `difit staged`
   - PR: `difit --pr <URL>`
2. 以下のコマンドを実行する:

```
difit [引数...]
```

- ユーザーが引数やオプションを指定した場合はそれに従う

## 主なオプション

- `--mode split|unified`: diff表示モード (デフォルト: split)
- `--pr <url>`: GitHub PRのURLを指定してレビュー
- `--tui`: ブラウザではなくターミナルUIで表示
- `--include-untracked`: untrackedファイルも含める
- `--context <lines>`: 変更周辺の表示行数

## 注意

- `difit` コマンドはブラウザを開いてサーバーを起動するため、`run_in_background` で実行する
- ブラウザを自動で開くために、`dangerouslyDisableSandbox: true` で実行する
