# 安全なコミットコマンド

main/masterブランチから直接コミットしないように保護するよ！🛡️

## 手順

### 1. ブランチ確認
現在のブランチが `main` または `master` かチェック:

```bash
git branch --show-current
```

### 2. 分岐処理

**main/masterの場合:**
1. ⚠️ 警告を表示
2. 変更内容を確認して適切なブランチ名を提案
3. ユーザーに確認してから新しいブランチを作成
   ```bash
   git checkout -b <branch-name>
   ```

**それ以外の場合:**
- そのまま次のステップへ進む

### 3. 変更確認
```bash
git status
git diff
git diff --staged
```

### 4. ステージング
必要に応じてファイルをステージング:
```bash
git add <files>
```

### 5. コミット作成
- Conventional Commits形式でメッセージを提案
- ユーザー確認後にコミット

```bash
git commit -m "type: description"
```

## Conventional Commits
| prefix | 用途 |
|--------|------|
| `feat:` | 新機能 |
| `fix:` | バグ修正 |
| `docs:` | ドキュメント |
| `refactor:` | リファクタリング |
| `test:` | テスト |
| `chore:` | その他（ビルド、CI等） |

## 注意事項
- 各ステップでユーザーに確認を取ること！🙋‍♀️
- ブランチ名はkebab-caseで変更内容を表す名前に
- コミットメッセージは簡潔に、でも何をしたか分かるように
