---
name: design-mock
description: UI/デザイン/画面レイアウト/コンポーネントを設計・提案するときに使用。文章で説明する代わりに、自己完結HTMLモックを書いてPlaywright CLIでスクショ→画像でユーザーに見せる。「デザイン作って」「画面イメージ見せて」「UI考えて」「レイアウト提案」「mockして」、または既存UIの改修案を提示する時に発火。実装前の合意形成フェーズで使う。
---

# Design Mock (HTMLモック→スクショ→画像提示)

UIの設計・提案は**文章で説明しない。必ずHTMLモックを作って画像で見せる**。複数状態(before/after, 各ステート)を1枚に並べると伝わる。

スクショは **Playwright CLI** (`npx playwright screenshot`) を使う。MCP サーバ・HTTP配信は不要(`file://` を直接渡せる ※後述)。

## ワークフロー

1. **対象UIの様式を把握**: 改修案なら既存コンポを読み、使ってるUIフレームワーク(react-bootstrap / Tailwind / MUI等)・実ラベル(i18n)・実データ形状を合わせる。空想の見た目でなく**実物に寄せる**ほど合意が早い。
2. **自己完結HTMLを書く** (`/tmp/<name>.html`): CSSは**インラインで自前**。CDN(bootstrap等)に依存しない(スクショ環境で読めない/遅い)。対象フレームワークの見た目を近似するだけでよい。複数ステートはラベル付きで縦に並べ、矢印で遷移を示す。
3. **スクショ** (Playwright CLI 一発。`file://` を直接渡す):
   ```sh
   npx --yes playwright@latest screenshot --full-page --viewport-size=860,1200 \
     "file:///tmp/<name>.html" /tmp/<name>.png
   ```
   - `--viewport-size` の **幅**を決める(カードUIなら 800〜860)。高さは初期値で、`--full-page` がコンテンツ全高を撮る
   - 出力パスを自分で指定するので **PNG探し不要・repo汚染なし**(`.playwright-mcp/` も落ちない)
   - ブラウザ(ヘッドレス Chromium)は内部で起動→終了するので `browser_close` 等の後始末不要
   - レンダ待ちが要るUI(Webフォント/遅延描画)は `--wait-for-timeout=500` を足す
4. **余白トリム** (任意・macOS `sips`): `--full-page` は基本コンテンツ高にフィットするので通常は不要。下に余白が出たときだけ:
   ```sh
   sips -g pixelWidth -g pixelHeight /tmp/<name>.png        # 寸法取得
   sips -c <新height> <width> /tmp/<name>.png --out /tmp/<name>_trim.png   # 上から切り抜き
   ```
5. **画像で配信**: `SendUserFile({files:["/tmp/<name>.png"], caption:"<各状態の要点>", status:"normal"})`。captionに各ステートの意図を1行で。トリムした場合は `_trim.png` を送る。
6. **後片付け**: `/tmp` 配下のみ。
   ```sh
   rm -f /tmp/<name>.html /tmp/<name>.png /tmp/<name>_trim.png
   ```

## なぜ HTTPサーバが要らないか

`file://` がブロックされるのは **Playwright MCP サーバ固有の制約**。Playwright 本体(CLI)にはこの制約がないので `file:///tmp/<name>.html` を直接ナビゲートできる。よって `python3 -m http.server` 工程は丸ごと不要。

## モックの質チェック

- 実フレームワークの見た目(角丸/影/バッジ色/プログレスバー/テーブル)を近似してるか
- 実ラベル・実データ形状(i18nキーやenum値)を使ってるか。ダミーすぎない
- before→after / 各状態の遷移が矢印・番号で読めるか
- 各状態の下に「何が嬉しいか/問題か」のキャプションを添えてるか

## 注意

- スクショは必ず `SendUserFile` で送る(パスを文章で伝えるだけは不可)
- 実装はこの後。モックは**合意形成用**。承認を得てからコード化する
- 既存ページに対する実ブラウザ操作(クリック遷移後の撮影・E2E)が要るなら `playwright-test` skill を使う。本 skill は静的HTMLの撮影に特化
