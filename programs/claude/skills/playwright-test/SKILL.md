---
name: playwright-test
description: Playwrightでブラウザテストを実行する。URL指定でスクリーンショット撮影、PDF保存、動画録画、E2Eテスト作成・実行が可能。ffmpegによる動画変換・GIF作成にも対応。
argument-hint: "<URL or テストファイルパス or コマンド>"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

`PLAYWRIGHT_BROWSERS_PATH`は環境変数設定済み(`~/.cache/ms-playwright`)。MCP Playwrightは使わず、`npx playwright` CLI経由で実行すること。動画処理は`ffmpeg`。

## ブラウザ初期化（初回 or バージョン更新時）

playwrightコマンド実行前に`npx playwright install chromium`でブラウザがインストール済みか確認。エラー`Executable doesn't exist`が出たら`npx playwright install chromium`を実行。

## $ARGUMENTSパース

**URL(https?://...)**: ユーザーに目的確認→screenshot/pdf/openのいずれか
- screenshot: `npx playwright screenshot --browser chromium "$URL" "/tmp/screenshot-$(date +%s).png"` opts: `--full-page`, `--viewport-size "W,H"`, `--wait-for-timeout MS`, `--device "NAME"`。撮影後Readで画像表示し確認
- pdf: `npx playwright pdf --browser chromium "$URL" "/tmp/page-$(date +%s).pdf"`
- open: `npx playwright open --browser chromium "$URL"`

**テストファイル(*.spec.ts,*.test.ts)**: `npx playwright test "$FILE" --reporter=list` opts: `--headed`, `--debug`, `--browser chromium`, `--grep "名"`, `--retries N`

**キーワード**: init→`npx playwright init-agents`, codegen→`npx playwright codegen`, report→`npx playwright show-report`, trace→`npx playwright show-trace <zip>`, test→`npx playwright test`, record→動画録画, gif→GIF変換, convert→動画変換

**テスト作成依頼**: 対象URL/シナリオ確認→`playwright.config.ts`なければ作成(testDir:'./tests', baseURL:'http://localhost:3000', chromiumプロジェクト)→`tests/`にspecファイル作成→実行→失敗時修正

**動画録画**: テストケースごとに独立した録画ファイルを生成する。スクリプトで`chromium.launch({headless:false})`→`newContext({recordVideo:{dir:'/tmp/playwright-videos/',size:{width:1280,height:720}}})`→操作→`context.close()`（close時に.webm保存）。実行は`npx tsx record.ts`。テスト内なら`test.use({video:'on'})`で`test-results/`に.webm生成。録画後はmp4に変換推奨（webmの1/3のサイズ）

**動画変換(ffmpeg)**:
- webm→mp4: `ffmpeg -i in.webm -c:v libx264 -crf 22 -y out.mp4`
- mp4→webm: `ffmpeg -i in.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -y out.webm`
- GIF(高品質): `ffmpeg -i in.webm -vf "fps=15,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 -y out.gif` opts: fps(10-15), scale, `-t SEC`, `-ss START -t DUR`
- トリミング: `ffmpeg -i in.mp4 -ss HH:MM:SS -t HH:MM:SS -c copy -y out.mp4`
- 解像度: `ffmpeg -i in.mp4 -vf "scale=W:H" -y out.mp4`
- 音声削除: `ffmpeg -i in.mp4 -an -y out.mp4`
- 結合: `ffmpeg -f concat -safe 0 -i list.txt -c copy -y out.mp4`

**引数なし**: `playwright.config.ts`/`tests/`/`package.json`のplaywright設定を確認→あればテスト実行提案、なければ目的確認

## 認証が必要な場合（op連携）

`op`（1Password CLI）で認証情報を取得してPlaywrightスクリプト内で自動ログインできる。

### 1Password アイテム一覧（omnicampus関連）
| アイテム名 | 用途 | URL |
|-----------|------|-----|
| `omn stg` | Staging Auth0ログイン | `https://omnicampus-staging.jp.auth0.com` |
| `omn prod` | Production Auth0ログイン | - |
| `AWS (omn stg)` | AWS Staging | - |
| `Omnicamp(grafana)` | Grafanaモニタリング | - |

### 認証情報の取得
```bash
# ユーザー名
op item get "omn stg" --fields username
# パスワード
op item get "omn stg" --fields password
```

### 自動ログインスクリプト例
```typescript
const username = execSync('op item get "omn stg" --fields username').toString().trim();
const password = execSync('op item get "omn stg" --fields password').toString().trim();
await page.fill('input[name="username"], input[type="email"]', username);
await page.fill('input[name="password"], input[type="password"]', password);
await page.click('button[type="submit"]');
```

### 手動ログイン（自動化困難な場合）
MFA/CAPTCHA等で自動ログインできない場合:
1. `chromium.launch({headless:false})`→`newContext()`→`page.goto(URL)`→ユーザーがログインするまで`page.waitForTimeout(120000)`→`context.storageState({path:'/tmp/auth-state.json'})`→close
2. 後続操作で`--save-storage /tmp/auth-state.json`または`test.use({storageState:'/tmp/auth-state.json'})`で認証状態を利用
3. 操作完了後`/tmp/auth-state.json`を削除

## トラブルシューティング

Browser not found→`npx playwright install chromium`を実行。Timeout→`--wait-for-timeout`増/`--wait-for-selector`使用。Navigation failed→URL/サーバー確認。GIF大→fps下げる/scale縮小/`-t`制限。webm再生不可→mp4変換。

## 出力

テスト結果: テスト数(合計/成功/失敗/スキップ), 実行時間, 失敗テスト名+エラー概要, スクリーンショットパス
