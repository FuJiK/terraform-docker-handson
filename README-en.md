# Docker Infrastructure with Terraform

This project demonstrates how to manage Docker infrastructure using Terraform.

## Prerequisites

- Docker installed and running
- Terraform >= 1.0

## Getting Started

1. Clone the repository:

```bash
git clone https://github.com/FuJiK/terraform-docker-handson.git
cd terraform-docker-handson
```

2. Initialize Terraform:

```bash
terraform init
```

3. Review the execution plan:

```bash
terraform plan
```

4. Apply the configuration:

```bash
terraform apply
```

5. Verify the deployment:

```bash
# Check running containers
docker ps

# Test web server
curl http://localhost:8080

# Test container communication
docker exec web_server ping -c 1 cache_server
```

6. Clean up resources:

```bash
terraform destroy
```

## Tests

```bash
./scripts/run-tests.sh
```

Runs Terraform tests, configuration checks, HTTP verification, and container communication checks. Results are written to `test-results/report.txt`.

## File Structure

- `providers.tf` - Provider configuration
- `variables.tf` - Variable definitions
- `main.tf` - Main resource definitions
- `outputs.tf` - Output definitions
- `tests/` - Terraform test definitions
- `scripts/run-tests.sh` - Verification script

## Resources Created

- Docker network (`app_network`)
- Nginx web server container (`web_server`)
- Redis cache container (`cache_server`)
