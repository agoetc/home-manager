# 安全なPR作成コマンド

main/masterブランチから直接コミットしないように保護しつつ、PRを作成するよ！💪

## 手順

### 1. ブランチ確認
現在のブランチが `main` または `master` かチェックして！

```bash
git branch --show-current
```

### 2. 分岐処理

**main/masterの場合:**
1. 変更内容を確認して適切なブランチ名を提案
2. ユーザーに確認してから新しいブランチを作成
   ```bash
   git checkout -b <branch-name>
   ```

**それ以外の場合:**
- そのまま次のステップへ進む

### 3. コミット作成
- `git status`と`git diff`で変更を確認
- コミットメッセージはConventional Commits形式で提案
- ユーザー確認後にコミット

### 4. プッシュ
```bash
git push -u origin <branch-name>
```

### 5. PR作成
`gh`コマンドでPRを作成:
```bash
gh pr create --fill
```

または内容を確認してから:
```bash
gh pr create --title "タイトル" --body "説明"
```

## 注意事項
- 各ステップでユーザーに確認を取ること！🙋‍♀️
- ブランチ名はkebab-caseで、変更内容を表す名前にする
- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
