# 図の設計と実装パターン

レポートの第1層は図が主役になる。ここでは「どの図を選ぶか」と「どう実装するか」を定める。
実装はすべて inline SVG または HTML+CSS（Artifact の CSP 下で確実に描画され、色と枠線を状態に割り当てられるため）。

## 目次

- [図の選択基準](#図の選択基準)
- [共通の記法](#共通の記法)
- [図A: 構造図に変更と検証状態を重ねる](#図a-構造図に変更と検証状態を重ねる)
- [図B: 充足度の帯](#図b-充足度の帯)
- [図C: 条件と結果のマトリクス](#図c-条件と結果のマトリクス)
- [図D: スキーマ・シグネチャの before/after 対比](#図d-スキーマシグネチャの-beforeafter-対比)
- [図E: 呼び出し元の追随状態](#図e-呼び出し元の追随状態)
- [アンチパターン](#アンチパターン)

## 図の選択基準

第1層には**構造を示す図1枚**と**分布を示す図1枚**（図B）を置く。構造を示す図は変更の形で選ぶ。

| 変更の形 | 構造を示す図 |
|---------|------------|
| 複数のコンポーネント・関数にまたがる。呼び出し関係が変わった | 図A（構造図に状態を重ねる） |
| 単一の関数・メソッドに閉じていて、入力に対する結果が変わった | 図C（条件と結果のマトリクス） |
| DBスキーマ・永続化フォーマット・公開シグネチャの変更が主 | 図D（before/after 対比） |
| 公開インターフェースの変更で、呼び出し元の追随が論点 | 図E（追随状態の一覧） |

複数該当する場合は、**変更の主題に対応する1枚**を選ぶ。残りは第2層以降で表として扱う。図を並べれば分かりやすくなるという判断は誤りで、読み手はまず「どの図を見るべきか」の判断を強いられる。

## 共通の記法

**2つの次元を1枚に重ねる。** 塗りが検証状態、枠線が変更の有無を表す。読み手が2枚の図を見比べる作業が消える。

| 次元 | 表現 | 意味 |
|-----|-----|-----|
| 塗り | 緑 `--st-ok` | ✅ 検証済み（値まで検証、壊れたら落ちる） |
| 塗り | 黄 `--st-weak` | ⚠️ 弱い（存在するが壊れても落ちない可能性） |
| 塗り | 灰 `--st-deferred` | ⏭️ 見送り（明示的な判断がある） |
| 塗り | 赤 `--st-missing` | ❌ 欠落（要求があるのに検証がない） |
| 塗り | 無色 `--surface` | 検証の要求がない |
| 枠線 | 太い実線 (`stroke-width="3"`) | この変更で変わった箇所 |
| 枠線 | 破線 (`stroke-dasharray="4 3"`) | 変わっていないが影響を受ける箇所 |
| 枠線 | 細い実線 (`stroke-width="1"`) | 変わっておらず影響もない（文脈として描くだけ） |

**凡例は必ず添える。** 色と枠線の意味が伝わらない図は、認知負荷を下げるどころか上げる。テンプレートに凡例のコンポーネントが含まれている。

## 図A: 構造図に変更と検証状態を重ねる

処理の流れ（誰が誰を呼ぶか）を box-and-arrow で描き、各ノードに検証状態と変更の有無を重ねる。「どの経路が守られていて、どこに穴があるか」が構造と一緒に読める。

```html
<figure class="dia">
  <svg viewBox="0 0 660 210" role="img"
       aria-label="リクエスト処理経路の各段階と、その検証状態">
    <defs>
      <marker id="arw" viewBox="0 0 10 10" refX="9" refY="5"
              markerWidth="7" markerHeight="7" orient="auto-start-reverse">
        <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--edge)"/>
      </marker>
    </defs>

    <!-- 変更あり・検証済み -->
    <g>
      <rect x="12" y="70" width="152" height="56" rx="6"
            fill="var(--st-ok-bg)" stroke="var(--st-ok)" stroke-width="3"/>
      <text x="88" y="94" text-anchor="middle" class="n">handler.PostSession</text>
      <text x="88" y="112" text-anchor="middle" class="s">正常系・異常系</text>
    </g>
    <line x1="164" y1="98" x2="196" y2="98"
          stroke="var(--edge)" stroke-width="1.5" marker-end="url(#arw)"/>

    <!-- 変更あり・弱い -->
    <g>
      <rect x="196" y="70" width="152" height="56" rx="6"
            fill="var(--st-weak-bg)" stroke="var(--st-weak)" stroke-width="3"/>
      <text x="272" y="94" text-anchor="middle" class="n">auth.Verify</text>
      <text x="272" y="112" text-anchor="middle" class="s">エラー有無のみ</text>
    </g>
    <line x1="348" y1="98" x2="380" y2="98"
          stroke="var(--edge)" stroke-width="1.5" marker-end="url(#arw)"/>

    <!-- 変更あり・欠落 -->
    <g>
      <rect x="380" y="70" width="152" height="56" rx="6"
            fill="var(--st-missing-bg)" stroke="var(--st-missing)" stroke-width="3"/>
      <text x="456" y="94" text-anchor="middle" class="n">store.Save</text>
      <text x="456" y="112" text-anchor="middle" class="s">制約違反が未検証</text>
    </g>
    <line x1="532" y1="98" x2="564" y2="98"
          stroke="var(--edge)" stroke-width="1.5" stroke-dasharray="4 3"
          marker-end="url(#arw)"/>

    <!-- 未変更・影響あり -->
    <g>
      <rect x="564" y="70" width="84" height="56" rx="6"
            fill="var(--surface)" stroke="var(--fg-dim)" stroke-width="1.5"
            stroke-dasharray="4 3"/>
      <text x="606" y="98" text-anchor="middle" class="n">PostgreSQL</text>
      <text x="606" y="114" text-anchor="middle" class="s">実接続なし</text>
    </g>
  </svg>
  <figcaption>リクエスト処理経路。太枠は本変更で変わった箇所、破線は変わっていないが影響を受ける箇所。塗りは検証状態。</figcaption>
</figure>
```

要点：

- **エッジにも状態を持たせられる。** 呼び出し経路そのものが検証されていない場合は、線を破線にして注記する（上の `store.Save → PostgreSQL` が実接続で検証されていない例）
- ノードが8個を超えると読めなくなる。その場合は領域単位（パッケージ、レイヤー）に集約して描き、関数単位の詳細は第3層のマトリクスに委ねる
- `viewBox` の座標は横 660 前後を基準にする。テンプレートの CSS が `max-width:100%` を当てるため、狭い画面でも縮んで収まる

## 図B: 充足度の帯

要求される検証の総数と、その状態の分布を1本の横棒で示す。「全体でどこまで届いているか」を数えずに把握できる。第1層に必ず置く。

```html
<figure class="dia">
  <div class="bar" role="img" aria-label="要求される検証17件のうち、検証済み9件、弱い3件、見送り2件、欠落3件">
    <span class="seg ok"       style="flex:9">9</span>
    <span class="seg weak"     style="flex:3">3</span>
    <span class="seg deferred" style="flex:2">2</span>
    <span class="seg missing"  style="flex:3">3</span>
  </div>
  <figcaption>要求される検証 17 件の内訳。左から 検証済み / 弱い / 見送り / 欠落。</figcaption>
</figure>
```

`flex` に件数をそのまま渡すと、幅が件数比になる。`role="img"` と `aria-label` に内訳を書いておくと、色が読めない環境でも内容が伝わる。

領域（パッケージ・機能）ごとに分けて複数本並べると、どの領域に欠落が集中しているかが見える。3〜8本までに収める。

## 図C: 条件と結果のマトリクス

変更が単一の関数に閉じている場合、構造図を描いても情報がない。代わりに「入力条件 → 変更前の結果 / 変更後の結果」の対応表を作り、各行に検証状態を色で重ねる。

```html
<table class="mx">
  <thead>
    <tr><th>入力条件</th><th>変更前</th><th>変更後</th><th>検証</th></tr>
  </thead>
  <tbody>
    <tr class="r-ok">
      <td>有効なトークン</td><td>ユーザーIDを返す</td><td>変わらず</td><td>✅ 値まで検証</td>
    </tr>
    <tr class="r-weak">
      <td>期限切れトークン</td><td><code>ErrExpired</code></td><td>変わらず</td><td>⚠️ エラー有無のみ</td>
    </tr>
    <tr class="r-missing">
      <td>署名が不正</td><td><code>ErrExpired</code>（誤り）</td><td><code>ErrInvalidSig</code></td><td>❌ なし</td>
    </tr>
    <tr class="r-deferred">
      <td>同時呼び出し</td><td>未定義</td><td>キャッシュを共有</td><td>⏭️ 見送り</td>
    </tr>
  </tbody>
</table>
```

これは表だが図として機能する。行の背景色で状態の分布が一目で見え、かつ個別の条件が読める。**変更前と変更後を同じ行に置くことが要点** — 別々の表に分けると読み手が対応付けをやり直すことになる。

## 図D: スキーマ・シグネチャの before/after 対比

DBスキーマ、永続化フォーマット、公開シグネチャの変更が主題のとき。2カラムを横並びにして、変更された行だけを強調する。

```html
<figure class="dia">
  <div class="ba">
    <div class="ba-col">
      <h4>変更前</h4>
      <pre><code>CREATE TABLE sessions (
  id    uuid PRIMARY KEY,
  token text NOT NULL
)</code></pre>
    </div>
    <div class="ba-col">
      <h4>変更後</h4>
      <pre><code>CREATE TABLE sessions (
  id    uuid PRIMARY KEY,
  token text NOT NULL,
  <mark>expires_at timestamptz NOT NULL</mark>
)</code></pre>
    </div>
  </div>
  <figcaption>強調部分が追加されたカラム。既存行のバックフィルが必要で、その検証は欠落している。</figcaption>
</figure>
```

`<mark>` で変更箇所を強調する。差分全体を貼るのではなく、**変更された定義だけを抜き出す** — 周辺を丸ごと貼ると強調が埋もれる。

スキーマ変更では、図の直下に「既存データの扱い」「後方互換性」「ロールバック可否」の3点それぞれに対する検証状態を必ず示す。この3つは欠落しても本番まで発覚しないため、レポートで最も価値のある情報になる。

## 図E: 呼び出し元の追随状態

公開インターフェースの変更で、全呼び出し元が追随できているかが論点のとき。

```html
<table class="mx">
  <thead><tr><th>呼び出し元</th><th>追随</th><th>検証</th></tr></thead>
  <tbody>
    <tr class="r-ok"><td><code>handler/session.go:45</code></td><td>新シグネチャに更新</td><td>✅</td></tr>
    <tr class="r-missing"><td><code>cmd/migrate/main.go:88</code></td><td>新シグネチャに更新</td><td>❌ この経路のテストなし</td></tr>
    <tr class="r-deferred"><td><code>examples/basic.go:12</code></td><td>未更新</td><td>⏭️ ビルド対象外</td></tr>
  </tbody>
</table>
```

呼び出し元の列挙は網羅性が要るので、grep で機械的に洗い出してから表にする。

```bash
grep -rn "FuncName(" --include="*.go" . | grep -v "_test.go"
```

## アンチパターン

- **変更箇所の図と検証状態の図を別々に出す。** 読み手が2枚を見比べて対応付ける作業が発生する。1枚に重ねる
- **凡例のない図。** 色の意味が伝わらず、読み手は本文を探しに行くことになる
- **同じ情報を図と表で二重に出す。** 分布・構造は図、個別項目と `file:line` は表に役割を分ける
- **差分をそのまま貼った図。** 差分は差分ビューアで読める。図の役割は、差分に現れない構造・経路・影響範囲を示すこと
- **ノードが多すぎる構造図。** 8個を超えたら領域単位に集約する
- **カバレッジ率の円グラフ。** 行カバレッジは「挙動が検証されているか」を答えないため、数値を図にしても判断材料にならない
