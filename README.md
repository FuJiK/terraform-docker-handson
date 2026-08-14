# Terraform による Docker インフラストラクチャ

このプロジェクトは、Terraform を使用して Docker インフラストラクチャを管理する方法を示しています。

## 前提条件

- Docker がインストールされ、実行中であること
- Terraform >= 1.0

## 使い方

1. リポジトリをクローンする:

```bash
git clone https://github.com/<your-username>/take-home-<id>.git
cd take-home-<id>
```

2. Terraform を初期化:

```bash
terraform init
```

3. 実行計画を確認:

```bash
terraform plan
```

4. 構成を適用:

```bash
terraform apply
```

5. デプロイを検証:

```bash
# 実行中のコンテナを確認
docker ps

# Web サーバーをテスト
curl http://localhost:8080

# コンテナ間通信をテスト
docker exec web_server ping -c 1 cache_server
```

6. リソースをクリーンアップ:

```bash
terraform destroy
```

## ファイル構成

- `providers.tf` - プロバイダー設定
- `variables.tf` - 変数定義
- `main.tf` - メインリソース定義
- `outputs.tf` - 出力定義

## 作成されるリソース

- Docker ネットワーク (`app_network`)
- Nginx Web サーバーコンテナ (`web_server`)
- Redis キャッシュコンテナ (`cache_server`)
