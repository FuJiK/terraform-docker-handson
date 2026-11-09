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
