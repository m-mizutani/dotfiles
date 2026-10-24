# 図の描き方

報告資料の図は inline SVG または HTML と CSS で描く。色はテンプレートの `:root` に定義したトークン（`var(--...)`）だけを使い、ライトテーマとダークテーマの両方で読めるようにする。SVG の文字とノードには、テンプレートの CSS に定義したクラス（`.n` `.s` `.node` `.focus` など）を使う。

## 目次

- [共通の規則](#共通の規則)
- [構成図](#構成図)
- [シーケンス図](#シーケンス図)
- [状態遷移図](#状態遷移図)
- [タイムライン](#タイムライン)
- [因果の連鎖](#因果の連鎖)
- [変更前と変更後の対比](#変更前と変更後の対比)
- [状態を重ねた構成図](#状態を重ねた構成図)
- [避けること](#避けること)

## 共通の規則

| 対象 | 規則 |
|-----|-----|
| 箱 | 1つの箱は1種類のもの（構成要素、データ1件、処理、状態）を表す。同じ図で種類を混ぜる場合は形を変え、凡例で示す |
| 矢印 | 1つの図で矢印の意味を1種類にする（呼び出し、データの移動、状態遷移、原因→結果）。2種類必要なら実線と破線で分け、凡例で示す |
| 強調 | 報告の対象は `.focus`（アクセント色の太枠）で示す。強調は1枚に1〜3か所まで |
| 状態 | 完了・正常は `--ok`、注意・進行中は `--warn`、失敗・未対応は `--bad`、対象外は `--muted` |
| 文字 | 箱の主ラベルは `.n`、補足は `.s`。1つの箱に2行まで。長い説明は本文に書く |
| 大きさ | `viewBox` の横幅は 640〜720 を基準にする。テンプレートの CSS が `max-width:100%` を指定するので、狭い画面では縮小される |
| 要素数 | 1枚の箱は8個まで。超える場合は上位の単位に集約し、詳細は別の図にする |
| 凡例 | 色、線種、形に意味を持たせた図には必ず凡例を付ける |
| 代替テキスト | `<svg role="img" aria-label="...">` に、図が示す内容を1文で書く |

矢印の先端は、各 SVG の `<defs>` に次の marker を定義して使う。SVG ごとに `id` を変える（同じページに同じ `id` が複数あると、どちらが参照されるかがブラウザに依存する）。

```html
<defs>
  <marker id="arw-1" viewBox="0 0 10 10" refX="9" refY="5"
          markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0 0 L10 5 L0 10 z" fill="var(--edge)"/>
  </marker>
</defs>
```

## 構成図

問い: 全体はどういう構成か。報告の対象はその中のどこか。

資料の冒頭の全体像に使う。報告の対象を `.focus` で強調し、それ以外は文脈として細い線で描く。読み手は「全体の中のどこの話か」を最初に把握できる。

```html
<figure class="dia">
  <svg viewBox="0 0 680 200" role="img" aria-label="ブラウザから API サーバーを経由してデータベースと外部の決済サービスに接続する構成。報告の対象は API サーバーと決済サービスの間の通信">
    <defs>
      <marker id="arw-arch" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M0 0 L10 5 L0 10 z" fill="var(--edge)"/>
      </marker>
    </defs>
    <rect class="node" x="10" y="70" width="130" height="56" rx="6"/>
    <text class="n" x="75" y="96" text-anchor="middle">ブラウザ</text>
    <text class="s" x="75" y="113" text-anchor="middle">利用者の画面</text>
    <line class="edge" x1="140" y1="98" x2="200" y2="98" marker-end="url(#arw-arch)"/>

    <rect class="node" x="200" y="70" width="150" height="56" rx="6"/>
    <text class="n" x="275" y="96" text-anchor="middle">API サーバー</text>
    <text class="s" x="275" y="113" text-anchor="middle">注文を受け付ける</text>

    <line class="edge" x1="350" y1="85" x2="470" y2="45" marker-end="url(#arw-arch)"/>
    <rect class="node" x="470" y="18" width="160" height="52" rx="6"/>
    <text class="n" x="550" y="49" text-anchor="middle">データベース</text>

    <line class="edge focus-edge" x1="350" y1="112" x2="470" y2="150" marker-end="url(#arw-arch)"/>
    <rect class="node focus" x="470" y="125" width="160" height="56" rx="6"/>
    <text class="n" x="550" y="151" text-anchor="middle">決済サービス</text>
    <text class="s" x="550" y="168" text-anchor="middle">外部のサービス</text>
  </svg>
  <figcaption>太枠が今回の報告の対象。矢印はリクエストの送信方向。</figcaption>
</figure>
```

## シーケンス図

問い: 処理はどの順序で進むか。誰が誰に何を渡すか。

参加者を横に並べ、縦の線（ライフライン）の間に、上から順にメッセージの矢印を描く。問題が起きたメッセージは `--bad` の色と注記で示す。参加者は5個まで。

```html
<figure class="dia">
  <svg viewBox="0 0 640 230" role="img" aria-label="API サーバーが決済サービスに決済を要求し、応答が30秒以内に返らずタイムアウトした順序">
    <defs>
      <marker id="arw-seq" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M0 0 L10 5 L0 10 z" fill="var(--edge)"/>
      </marker>
      <marker id="arw-seq-bad" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M0 0 L10 5 L0 10 z" fill="var(--bad)"/>
      </marker>
    </defs>
    <!-- participants -->
    <rect class="node" x="40" y="10" width="120" height="34" rx="5"/><text class="n" x="100" y="32" text-anchor="middle">ブラウザ</text>
    <rect class="node" x="260" y="10" width="120" height="34" rx="5"/><text class="n" x="320" y="32" text-anchor="middle">API サーバー</text>
    <rect class="node focus" x="480" y="10" width="120" height="34" rx="5"/><text class="n" x="540" y="32" text-anchor="middle">決済サービス</text>
    <!-- lifelines -->
    <line class="lifeline" x1="100" y1="44" x2="100" y2="220"/>
    <line class="lifeline" x1="320" y1="44" x2="320" y2="220"/>
    <line class="lifeline" x1="540" y1="44" x2="540" y2="220"/>
    <!-- messages, top to bottom -->
    <line class="edge" x1="100" y1="75" x2="318" y2="75" marker-end="url(#arw-seq)"/>
    <text class="s" x="210" y="68" text-anchor="middle">1. 注文を確定</text>
    <line class="edge" x1="320" y1="115" x2="538" y2="115" marker-end="url(#arw-seq)"/>
    <text class="s" x="430" y="108" text-anchor="middle">2. 決済を要求</text>
    <line class="edge bad-edge" x1="538" y1="160" x2="322" y2="160" marker-end="url(#arw-seq-bad)"/>
    <text class="s bad-text" x="430" y="153" text-anchor="middle">3. 応答なし（30秒でタイムアウト）</text>
    <line class="edge" x1="318" y1="200" x2="102" y2="200" marker-end="url(#arw-seq)"/>
    <text class="s" x="210" y="193" text-anchor="middle">4. エラー画面を返す</text>
  </svg>
  <figcaption>番号はメッセージの順序。赤の矢印が失敗した箇所。</figcaption>
</figure>
```

## 状態遷移図

問い: 対象はどの状態をとり、何をきっかけに次の状態に移るか。

状態を角の丸い箱、遷移を矢印、遷移のきっかけ（イベント）を矢印のラベルで示す。問題に関係する遷移や、到達してはいけない状態を強調する。

骨格は構成図と同じで、次の点だけ変える。

- 箱は `rx="18"` にして、構成要素の箱と区別する
- 矢印のラベルは「イベント名 / 条件」の形にする
- 自己遷移（同じ状態に戻る）は `<path d="M x y C ...">` の曲線で描く
- 開始状態の前に小さな黒丸（`<circle r="6" fill="var(--fg)">`）を置く

## タイムライン

問い: いつ何が起きたか。どの時点から影響が出て、いつ解消したか。

横軸を時刻にして、出来事を点、影響が出ていた期間を帯で示す。HTML と CSS で描くと、文字が長くても折り返せる。

```html
<figure class="dia">
  <ol class="tl">
    <li><time>10/22 13:05</time><span>決済サービスの応答時間が増加</span></li>
    <li class="bad"><time>13:20</time><span>注文の確定が失敗し始める（影響開始）</span></li>
    <li><time>14:10</time><span>アラートを受けて調査を開始</span></li>
    <li class="ok"><time>16:15</time><span>タイムアウト値を変更し、注文の確定が成功（影響終了）</span></li>
  </ol>
  <figcaption>赤が影響の開始、緑が影響の終了。影響が出ていた期間は 13:20〜16:15 の約3時間。</figcaption>
</figure>
```

## 因果の連鎖

問い: 何が原因で、何が起きたか。どこで止めれば防げたか。

原因から結果へ左から右（狭い画面では上から下）に箱を並べ、矢印でつなぐ。根本原因の箱を `--bad`、対処を入れた箇所を `--ok` で示す。HTML と CSS の `.chain` を使うと、画面幅に応じて縦横が切り替わる。

```html
<figure class="dia">
  <div class="chain">
    <div class="step bad"><b>決済サービスの応答遅延</b><span>平均 0.4秒 → 35秒</span></div>
    <div class="step"><b>API サーバーの接続が枯渇</b><span>上限 50 本すべてが応答待ち</span></div>
    <div class="step ok"><b>注文の確定が失敗</b><span>対処: タイムアウトを 30秒 → 5秒</span></div>
  </div>
  <figcaption>左が原因、右が結果。赤が根本原因、緑が対処を入れた箇所。</figcaption>
</figure>
```

「原因」と書く箱は、確認済みの事実に限る。推測した原因は箱を破線（`.step.guess`）にし、凡例で「推測」と示す。

## 変更前と変更後の対比

問い: 何が変わり、何が変わっていないか。

**同じ配置、同じ名前、同じ大きさの図を2枚並べる。** 配置が違うと、読み手は対応する箱を探すところから始めることになる。変わった箱だけを `.focus` で強調し、追加した要素は `--ok`、削除した要素は破線で示す。テンプレートの `.ba`（2列のグリッド。狭い画面では1列）に配置する。

## 状態を重ねた構成図

問い: どの構成要素が完了し、どれが残っているか。

構成図の各箱を状態の色で塗る。「構成図」と「状態の一覧表」を別々に出すと、読み手は2つを見比べて対応付けることになるので、1枚に重ねる。箱の塗りは `class="node st-ok"` `st-warn` `st-bad` `st-muted` で指定する。凡例は必須。

## 避けること

- **本文の箇条書きを箱に置き換えただけの図。** 箱の間に関係（矢印、包含、順序）がなければ、図にする意味がない
- **1枚に主張を詰め込んだ図。** 構成、順序、状態を1枚に描くと、読み手はまず図の読み方を解読することになる
- **図ごとに異なる名前や色の意味。** 同じ構成要素はすべての図で同じ名前、同じ位置関係で描く。色の意味は資料全体で統一する
- **凡例のない図。**
- **画像の埋め込み（PNG など）。** テーマに合わせて色が変わらず、文字を検索できない
