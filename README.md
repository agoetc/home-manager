## 適用
```sh
git add -A && nix flake update && home-manager switch
```

## 事前install
- nixのインストール
  - https://nix.dev/manual/nix/2.24/installation/
- home-managerのインストール
  - https://nix-community.github.io/home-manager/index.html#sec-install-standalone

## 最初にやる
```sh
git clone https://github.com/agoetc/home-manager.git
cd home-manager
sh copy-to-home.sh
```

`copy-to-home.sh` が以下を実行する:
1. リポジトリを `~/.config/home-manager/` にコピー
2. age 秘密鍵の入力 (`~/Library/Application Support/sops/age/keys.txt` に保存)
3. `home-manager switch` で設定を適用

## シークレット管理 (sops-nix)

secrets.yaml は age 鍵で暗号化されており、git コミット可能。

```sh
# シークレットの編集
nix-shell -p sops --run "sops secrets.yaml"
```
