# AWS WordPress / MariaDB lab (Terraform + Ansible)

Two-EC2 learning environment in AWS Tokyo. **GitHub pushes do not provision AWS resources.**
No RDS, NAT Gateway, Application Load Balancer, EIP or paid VPC interface endpoints.

## Architecture

```text
                         trusted admin IP /32
                             │ SSH 22 / HTTP 80
                             ▼
Internet ─ IGW ─ Public subnet 10.40.0.0/24
                       Web EC2 (Ubuntu 24.04)
                       Nginx + PHP-FPM + WordPress
                       Squid HTTP(S) proxy :3128
                             │
                ┌────────────┼──────────────┐
                │ SSH :22    │ SQL :3306    │ proxy :3128 (DB -> web)
                ▼            ▼              ▲
Private subnet 10.40.10.0/24
           DB EC2 (Ubuntu 24.04 + MariaDB)
           no public IP, no NAT, no default internet route
```

VPC: `10.40.0.0/16`. An additional public and private subnet exists in a second AZ for future expansion.
Both EC2 instances start in the first AZ. DB package installation uses a restricted Squid forward proxy
on the public web EC2. Ansible connects to the private DB using SSH ProxyJump via the web EC2.

**Lab limitations:** This is a single-AZ workload, not a highly available production environment.
Web HTTP is *unencrypted* and is restricted to the trusted admin CIDR for initial training. Do not use
real personal information or production passwords. Before opening access to general users, configure
a DNS name, TLS/HTTPS, automatic renewals, backups, OS patches, rate limiting and an appropriate web security design.

## Requirements

- Terraform >=1.6 with AWS provider 6.x; AWS credentials for the intended AWS account
- AWS CLI for account verification (recommended)
- Ansible Core + `community.mysql` collection, Python 3 on control node
- SSH key pair **already created in ap-northeast-1**, corresponding private key on the control node
- Trusted public IPv4 /32 address
- Egress internet access from the public web EC2

> **Costs:** Two EC2 instances, two gp3 EBS root volumes and an automatically assigned public IPv4
> can accrue charges while running, regardless of WordPress traffic. A public IPv4 is billed.
> The variable defaults to `enable_wordpress_lab = false`, so the initial network-only deployment
> remains the default. Free Tier and promotional credit applicability vary by account and service.
> Squid removes the need for a managed NAT Gateway but creates an operational dependency on the web EC2.

## Step 1 — Terraform

```bash
git clone https://github.com/FuJiK/terraform-docker-handson.git
cd terraform-docker-handson
git switch feat/aws-network-foundation
cd aws-network

cp terraform.tfvars.wordpress.example terraform.tfvars
# Edit terraform.tfvars:
# - admin_cidr = your actual public IPv4 /32, NEVER 0.0.0.0/0
# - ssh_key_name = an existing EC2 key pair name in the Tokyo region
# - enable_wordpress_lab = true

aws sts get-caller-identity
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=network.tfplan

# Inspect the plan. Only after confirming the AWS account, resources and costs:
terraform apply network.tfplan
terraform output
```

The original network-only configuration can still use
`cp terraform.tfvars.example terraform.tfvars` instead; EC2 resources remain disabled.

## Step 2 — Ansible (from your local control node)

Wait until EC2 cloud-init completes on the web host and Squid is active.
From `aws-network/`:

```bash
python3 ansible/generate_inventory.py
cd ansible

ansible-galaxy collection install -r requirements.yml
cp vars/secrets.example.yml vars/secrets.yml
# Edit vars/secrets.yml with unique, long random passwords and a lab-only email.
ansible-vault encrypt vars/secrets.yml

# Pass the path to your EXISTING local SSH private key. Do not commit it.
ansible -i inventory/hosts.json all -m ping --private-key ~/.ssh/aws-lab.pem
ansible-playbook -i inventory/hosts.json site.yml \
  --private-key ~/.ssh/aws-lab.pem --ask-vault-pass
```

If the first SSH connection requests host-key confirmation, verify the host identity before
accepting it. The inventory file and plaintext secrets are ignored by Git.
The controller needs a usable OpenSSH client for ProxyJump.

The playbook does the following:
1. Routes DB host APT package requests through the restricted Squid proxy.
2. Installs MariaDB on the private host, binds to its private address and creates a restricted DB user.
3. Installs Nginx, PHP 8.3 and WordPress on the web host.
4. Generates WordPress config and completes the initial WordPress installation using vaulted credentials.

After the playbook succeeds, test the website from the **admin IP only**:
`http://<web_public_ip>/`. Do not enter sensitive credentials over HTTP.
For a public-facing site, add HTTPS **before** login or general exposure.

## Verification

```bash
terraform output web_public_ip
terraform output db_private_ip
terraform state list
cd ansible
ansible -i inventory/hosts.json all -m ping --private-key ~/.ssh/aws-lab.pem
```

Test DB connectivity using the vaulted credential from the web host only.
Database port 3306 and the proxy port 3128 must not be publicly reachable.

## Cleanup

```bash
cd aws-network
terraform plan -destroy
terraform destroy
```

Destroying the lab **deletes EC2 root EBS volumes and MariaDB data**.
Export database backups first if anything matters. Also remove any orphaned
resources and review the AWS bill after deletion.

## Security notes

- No plaintext passwords in Terraform, Git or EC2 user-data.
- Ansible secrets are kept outside Git, encrypted with Ansible Vault.
- SSH and HTTP inbound allowed only from the trusted admin CIDR.
- DB SSH inbound allowed only from web SG; MariaDB TCP/3306 allowed only from web SG.
- Private DB EC2 has no public IP; private subnet has only the VPC-local route.
- IMDSv2 required; EBS root storage encrypted.
- This minimal lab does not include TLS, automated backup, malware scanning,
  formal patch management or disaster recovery.

---

## 今後の展望 / Learning Roadmap

このリポジトリは、WordPressを公開すること自体よりも、AWSのネットワーク、Infrastructure as Code、OS・ミドルウェア構成管理、CI/CD、認証・認可、監視と障害復旧を段階的に学ぶためのハンズオンです。

**方針:** 最初はシンプルな2台構成で仕組みを理解し、次にGitHub ActionsとOIDCによる安全な自動化を導入する。高可用性やマネージドサービスへの移行は、必要性・費用・学習目的を比較してから判断する。

### Phase 1：ネットワーク基盤（実装済み・AWS未デプロイ）

- [x] VPC（`10.40.0.0/16`）、Internet Gateway
- [x] 2つのAvailability ZoneにPublic / Private Subnetを配置
- [x] Route TableとSubnet Association
- [ ] `terraform fmt`、`terraform validate`、`terraform plan`で検証
- [ ] AWSコンソールでルーティング、サブネット、デフォルトルートを確認

**学習ポイント:** CIDR、ルーティング、SGとNACLの違い、Public/Private Subnetの成立条件。

### Phase 2：EC2＋Ansible＋WordPress/MariaDB（コード作成済み・未検証／未デプロイ）

- [x] Web用EC2をPublic Subnet、DB用EC2をPrivate Subnetに配置するTerraformコード
- [x] Nginx・PHP-FPM・WordPress・MariaDBのAnsible Playbook
- [x] Web EC2を踏み台とするSSH ProxyJump
- [x] NAT Gatewayの代わりにWeb EC2上の限定プロキシを経由するDBパッケージ取得
- [ ] TerraformとAnsibleの構文・静的検証、`plan`の確認
- [ ] Ansibleを繰り返し実行して冪等性を確認
- [ ] Web→DBのTCP/3306通信と接続制限を確認
- [ ] 障害・再実行・復旧の手順を記録

**学習ポイント:** IAMとSSH認証の違い、Linux、systemd、APT、Ansible Inventory・Role化・Handlers・冪等性。

### Phase 3：GitHub Actions＋AWS OIDC認証（計画）

- [ ] TerraformでIAM OIDC Providerと専用IAM Roleを定義
- [ ] GitHubの対象リポジトリ／ブランチ／環境のみに絞るTrust Policyを設計
- [ ] AWS権限は最小権限で付与し、Plan用とApply用の権限分離を検討
- [ ] ワークフローに `permissions: contents: read` と `id-token: write` を設定
- [ ] `aws sts get-caller-identity` によるOIDC認証テスト
- [ ] 長期有効なAWSアクセスキーをGitHub Secretsに保存しない

**重要:** OIDCで認証するのは **GitHub Actions → AWS**。WordPress → MariaDBのパスワード認証を置き換えるものではありません。

OIDC Provider／IAM Roleの初回作成（Bootstrap）には、既存の管理者権限等が必要です。GitHubのOIDC `sub` クレーム形式とIAMの信頼条件は、実際の発行トークンと現行ドキュメントに合わせて検証します。

### Phase 4：Terraform CI/CDとState管理（計画）

- [ ] GitHub Actionsで `terraform fmt -check`・`validate`・`plan` を実施
- [ ] PRでTerraform差分をレビュー可能にする
- [ ] Applyは保護されたGitHub Environmentの承認後に限定する
- [ ] Terraform Stateの保存先をS3へ移行（S3 Backend、暗号化、バージョニング、ロック）
- [ ] BackendのBootstrapとアクセス制御をアプリ基盤から分離する
- [ ] CI/CDからのDestroyを無条件・自動実行しない
- [ ] 複数環境（dev／stg）のディレクトリ・State分離を検討

**学習ポイント:** PRレビュー、ドリフト検出、Stateロック、最小権限、CI/CDでの承認フロー。

### Phase 5：DBパスワードとSecret管理（計画）

- [x] サンプルファイルには実際のパスワードを保存しない
- [x] Ansible Vaultでローカルのシークレットを暗号化する方針
- [ ] WordPress初期設定時のパスワードをCLI引数として渡さないよう改善
- [ ] `no_log: true` とファイルアクセス権、シークレットの取り扱いを確認
- [ ] 環境変数・Ansible Vault・AWS Secrets Managerの利点とリスクを比較
- [ ] 必要に応じてIAM RoleによるSecrets Manager取得とDBパスワードのローテーションを試す

**重要:** 環境変数もAnsible Vaultも万能ではありません。Git履歴・ログ・プロセス引数・Terraform State・EC2 user-dataに秘密情報が露出しない設計にします。

### Phase 6：HTTPS・監視・バックアップ（計画）

- [ ] DNS／TLS証明書／HTTPSリダイレクトを導入（一般公開や管理画面ログインより前）
- [ ] WordPress・Nginx・MariaDBのログ収集と分析
- [ ] CloudWatch Agent、メトリクス、アラームの導入
- [ ] EBSスナップショットやDB論理バックアップ、リストア演習
- [ ] OS・PHP・WordPress・MariaDBの更新手順の整備
- [ ] AWS Budgetsでコスト上限通知を設定し、クレジット期限も定期的に確認

**学習ポイント:** 可観測性、SLO、MTTR、バックアップと復旧、運用Toil削減。

### Phase 7：発展・アーキテクチャ改善（将来検討）

- [ ] SSH踏み台／Squid依存の低減（SSMや適切なVPC Endpoint、接続方式を比較）
- [ ] Ansible Role・タグ・テスト（Molecule等）による構成の再利用
- [ ] Multi-AZ・ロードバランサ・DB冗長化の費用対効果を比較
- [ ] 意図的なWeb停止／DB停止／設定ドリフトの検出と復旧
- [ ] RDSなどマネージドDBとの運用責任・コスト比較（移行は必須ではない）

### セキュリティ・コストに関する共通原則

1. **GitHubへPushしただけではAWSへApplyしない。** 初回デプロイと破壊操作にはレビューを挟む。
2. **EC2、EBS、Public IPv4、監視、通信等は課金対象になり得る。** AWSクレジットがあっても予算を確認する。
3. **HTTPのままWordPressに本物の認証情報や個人情報を入力しない。** HTTPS整備前は閉じた検証用途に限る。
4. Private SubnetのDBをインターネットへ公開しない。必要なポートのみSecurity Groupで許可する。
5. 再現性を重視し、構築・設定変更・バックアップ・復旧・削除までコードと手順で管理する。

### 学習完了の目安

| 分野 | 検証内容 |
| --- | --- |
| Terraform | 同じコードで再構築でき、PlanとStateの差分を説明できる |
| AWS Networking | WebからDBへ接続でき、不要な外部通信が拒否されていることを確認できる |
| Ansible | Playbookの2回目実行で不要な変更が発生しない |
| IAM/OIDC | 長期AWSキーなしでGitHub Actionsから許可されたAWS操作を実行できる |
| Security | DBの非公開化、Secret保護、HTTPS、権限の最小化を説明できる |
| Operations | ログ・アラームから異常を発見し、バックアップから復元できる |
