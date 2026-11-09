# AWS Network Foundation (Terraform)

Minimal, low-cost AWS network lab in Tokyo (`ap-northeast-1`).

## Architecture

```text
VPC 10.40.0.0/16
├─ Internet Gateway
├─ Public route table (0.0.0.0/0 -> IGW)
│  ├─ Public subnet A  10.40.0.0/24  (ap-northeast-1a)
│  └─ Public subnet C  10.40.1.0/24  (ap-northeast-1c)
└─ Private route tables (local routes only, no NAT)
   ├─ Private subnet A 10.40.10.0/24 (ap-northeast-1a)
   └─ Private subnet C 10.40.11.0/24 (ap-northeast-1c)
```

## Principles

- No NAT Gateway, EC2, load balancer, RDS, Elastic IP or VPC endpoints.
- No AWS resources are created by a Git push or Terraform plan.
- Subnets do not auto-assign public IPv4 addresses.
- Private subnets have no route to the public internet.
- **Public subnet != publicly accessible instance**: exposure also depends on public IPs, security groups and resource configuration.
- VPC, subnet, route table and internet gateway usually do not have hourly resource charges; future additions (notably public IPv4 addresses, NAT, endpoints and data transfer) may incur fees.
- Availability zone names are account-specific mappings. Confirm the selected AZs are available.
- State is local for this lab; never commit `terraform.tfstate`. For teamwork, set up a protected remote backend with locking.

## Run locally

Prerequisites: Terraform 1.6+ and authenticated AWS credentials (AWS CLI profile / SSO / environment). The AWS provider version constraint is `~> 6.0`.

```bash
cd aws-network
cp terraform.tfvars.example terraform.tfvars
aws sts get-caller-identity
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=network.tfplan
terraform apply network.tfplan
terraform output
```

Do **not** run `apply` until you inspect the plan. Check that the authenticated AWS account is the intended target. Never commit keys, .tfvars with secrets, state files or plan files.

## Destroy

```bash
terraform plan -destroy
terraform destroy
```

Deleting the lab network removes its resources and is irreversible. Do not attach workload resources before destroying.

## Next steps

Possible additions: restricted security groups, private EC2 with SSM access through VPC endpoints, RDS PostgreSQL, ALB and observability. Add these only after reviewing cost.
