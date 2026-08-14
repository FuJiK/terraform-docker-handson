# Terraform による Docker インフラストラクチャ

このプロジェクトは、Terraform を使用して Docker インフラストラクチャを管理する方法を示しています。

## 前提条件

- Docker がインストールされ、実行中であること
- Terraform >= 1.0

## 使い方

1. リポジトリをクローンする:

```bash
git clone https://github.com/FuJiK/terraform-docker-handson.git
cd terraform-docker-handson
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

## テスト

```bash
./scripts/run-tests.sh
```

`terraform test`、構成検証、HTTP 応答、コンテナ間通信までをまとめて確認します。結果は `test-results/report.txt` に出力されます。

## ファイル構成

- `providers.tf` - プロバイダー設定
- `variables.tf` - 変数定義
- `main.tf` - メインリソース定義
- `outputs.tf` - 出力定義
- `tests/` - Terraform テスト定義
- `scripts/run-tests.sh` - 検証スクリプト

## 作成されるリソース

- Docker ネットワーク (`app_network`)
- Nginx Web サーバーコンテナ (`web_server`)
- Redis キャッシュコンテナ (`cache_server`)
