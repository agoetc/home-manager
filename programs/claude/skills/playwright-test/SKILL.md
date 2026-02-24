---
name: playwright-test
description: Playwrightでブラウザテストを実行する。URL指定でスクリーンショット撮影、PDF保存、動画録画、E2Eテスト作成・実行が可能。ffmpegによる動画変換・GIF作成にも対応。
argument-hint: "<URL or テストファイルパス or コマンド>"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Playwright ブラウザテスト

Nix管理のPlaywrightとffmpegを使ってブラウザテスト・録画を実行する。
`PLAYWRIGHT_BROWSERS_PATH` は環境変数で設定済み。Playwrightコマンドは `npx playwright` 経由、動画処理は `ffmpeg` で実行する。

## 引数のパース

`$ARGUMENTS` を以下のルールで判定する:

### 1. URL の場合（https?://...）

ユーザーにやりたいことを確認し、以下のいずれかを実行する:

#### スクリーンショット撮影

```bash
npx playwright screenshot --browser chromium "$URL" "/tmp/screenshot-$(date +%s).png"
```

オプション:
- `--full-page`: ページ全体をキャプチャ
- `--viewport-size "1280,720"`: ビューポートサイズ指定
- `--wait-for-timeout 3000`: 描画待ち（ms）
- `--device "iPhone 13"`: デバイスエミュレーション

撮影後、Read ツールで画像を表示してユーザーに確認する。

#### PDF保存

```bash
npx playwright pdf --browser chromium "$URL" "/tmp/page-$(date +%s).pdf"
```

#### ページを開いて確認

```bash
npx playwright open --browser chromium "$URL"
```

### 2. テストファイルパスの場合（*.spec.ts, *.test.ts）

既存テストを実行する:

```bash
npx playwright test "$FILE_PATH" --reporter=list
```

オプション:
- `--headed`: ブラウザを表示して実行
- `--debug`: デバッグモードで実行
- `--browser chromium`: ブラウザ指定
- `--grep "テスト名"`: 特定テストのみ実行
- `--retries 2`: リトライ回数

### 3. コマンドキーワードの場合

| キーワード | 実行内容 |
|-----------|---------|
| init | `npx playwright init-agents` でプロジェクト初期化 |
| codegen | `npx playwright codegen` でコード生成（ブラウザ操作を記録） |
| report | `npx playwright show-report` でHTMLレポート表示 |
| trace | `npx playwright show-trace <trace.zip>` でトレース確認 |
| test | `npx playwright test` で全テスト実行 |
| record | URL を指定してブラウザ操作を動画録画（下記「動画録画」参照） |
| gif | 動画ファイルをGIFに変換（下記「GIF変換」参照） |
| convert | 動画フォーマット変換（下記「動画変換」参照） |

### 4. テスト作成の依頼の場合

以下の手順でE2Eテストを作成する:

#### Step 1: テスト対象の確認

- 対象URLまたはコンポーネントを確認
- テストシナリオ（何を検証するか）を確認

#### Step 2: テストファイルの作成

`playwright.config.ts` が存在するか確認し、なければ作成:

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
  ],
});
```

テストファイルを `tests/` 以下に作成:

```typescript
import { test, expect } from '@playwright/test';

test.describe('機能名', () => {
  test('テストケース名', async ({ page }) => {
    await page.goto('/path');
    // アサーション
    await expect(page).toHaveTitle(/expected/);
  });
});
```

#### Step 3: テスト実行と結果確認

```bash
npx playwright test tests/対象ファイル.spec.ts --reporter=list
```

失敗した場合はエラー内容を分析し、テストコードを修正する。

### 5. 動画録画・変換の場合

#### 動画録画（Playwright テスト内）

テストの `video` オプションを有効にして録画する:

```typescript
import { test, expect } from '@playwright/test';

test.use({ video: 'on' });

test('操作を録画', async ({ page }) => {
  await page.goto('https://example.com');
  // ユーザー操作をシミュレート
  await page.click('text=Link');
  await page.waitForTimeout(2000);
});
```

実行すると `test-results/` に `.webm` ファイルが生成される:

```bash
npx playwright test tests/record.spec.ts --reporter=list
```

#### 動画録画（スクリプトで直接）

テストフレームワークを使わず、Playwrightスクリプトで録画する:

```typescript
// record.ts
import { chromium } from 'playwright';

const browser = await chromium.launch();
const context = await browser.newContext({
  recordVideo: { dir: '/tmp/videos', size: { width: 1280, height: 720 } }
});
const page = await context.newPage();
await page.goto('https://example.com');
// 操作...
await page.waitForTimeout(3000);
await context.close();
await browser.close();
```

```bash
npx tsx record.ts
```

#### webm → mp4 変換（ffmpeg）

Playwrightの録画は `.webm` 形式なので、共有しやすい `.mp4` に変換:

```bash
ffmpeg -i /tmp/videos/recording.webm -c:v libx264 -preset fast -crf 22 -y /tmp/videos/recording.mp4
```

#### GIF変換（ffmpeg）

動画やwebmをSlack等に貼れるGIFに変換:

```bash
# 高品質GIF（パレット最適化）
ffmpeg -i input.webm -vf "fps=15,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 -y /tmp/output.gif
```

オプション:
- `fps=15`: フレームレート（低いほど軽い。Slack向けは10-15推奨）
- `scale=640:-1`: 横幅640pxにリサイズ（アスペクト比維持）
- `-t 10`: 最初の10秒だけ変換
- `-ss 5 -t 10`: 5秒目から10秒間を変換

#### 動画変換（ffmpeg 汎用）

| 変換 | コマンド |
|------|---------|
| webm → mp4 | `ffmpeg -i in.webm -c:v libx264 -crf 22 -y out.mp4` |
| mp4 → webm | `ffmpeg -i in.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -y out.webm` |
| 動画トリミング | `ffmpeg -i in.mp4 -ss 00:00:05 -t 00:00:10 -c copy -y out.mp4` |
| 解像度変更 | `ffmpeg -i in.mp4 -vf "scale=1280:720" -y out.mp4` |
| 音声削除 | `ffmpeg -i in.mp4 -an -y out_silent.mp4` |
| 動画結合 | `ffmpeg -f concat -safe 0 -i list.txt -c copy -y out.mp4` |

### 6. 引数なしの場合

以下を確認してユーザーに提案する:

1. カレントディレクトリに `playwright.config.ts` があるか
2. `tests/` ディレクトリにテストファイルがあるか
3. `package.json` に playwright 関連のスクリプトがあるか

存在する場合は既存テストの実行を提案。なければ何をしたいか確認する。

## トラブルシューティング

| エラー | 対処 |
|-------|------|
| Browser not found | `PLAYWRIGHT_BROWSERS_PATH` が設定されているか確認。`echo $PLAYWRIGHT_BROWSERS_PATH` |
| Timeout | `--wait-for-timeout` を増やす。SPAの場合は `--wait-for-selector` を使う |
| Navigation failed | URLが正しいか、サーバーが起動しているか確認 |
| ffmpeg not found | `which ffmpeg` で確認。Nix の packages に含まれているはず |
| GIF が大きすぎる | `fps` を下げる、`scale` で幅を小さくする、`-t` で秒数を制限する |
| webm 再生できない | `ffmpeg -i in.webm -c:v libx264 -crf 22 out.mp4` で mp4 に変換 |

## 出力フォーマット

テスト結果は以下の形式で報告する:

| 項目 | 値 |
|------|------|
| テスト数 | 合計 / 成功 / 失敗 / スキップ |
| 実行時間 | 秒数 |
| 失敗テスト | テスト名とエラー概要 |
| スクリーンショット | ファイルパス（あれば） |
