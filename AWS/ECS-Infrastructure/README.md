# Phase 2 — ECS Infrastructure

Deploys **seven Fargate services** on an ECS cluster behind an **Application Load Balancer** (HTTPS) with **Route 53** DNS.

This is **Phase 2** of the repo. Complete **Phase 1 (VPC networking)** in [../../README.md](../../README.md) before running Terraform here.

---

## Prerequisites

### From Phase 1 (required)

Apply the networking stack under `AWS/` and copy outputs into `terraform.tfvars`:

```bash
cd ../   # AWS/ (networking root)
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids
```

| Output | `terraform.tfvars` variable |
|--------|----------------------------|
| `vpc_id` | `vpc_id` |
| `public_subnet_ids` | `public_subnet_ids` (ALB) |
| `private_subnet_ids` | `private_subnet_ids` (ECS tasks) |

`aws_region` in this stack **must match** the region where the VPC was created.

### Account setup (from root README)

| Item | Detail |
|------|--------|
| AWS CLI profile | Same as Phase 1 (e.g. `terraform-infra`) |
| S3 + DynamoDB state | Same bucket; **different** state `key` — e.g. `ECS-Infrastructure/dev/terraform.tfstate` |
| IAM | `../iampolicies/terraform-state-backend.json.example` + `../iampolicies/terraform-ecs.json.example` |

### Before `terraform apply` (Phase 2 only)

| # | Item | Action |
|---|------|--------|
| 1 | **ACM** | Certificate in ALB region covering your hostnames → `acm_certificate_arn` |
| 2 | **Route 53** | Public zone for `route53_domain_name`; optional `route53_hosted_zone_id` |
| 3 | **ECR / images** | Build and push images; set `image` per service in `ecs_task_definitions` |
| 4 | **Secrets** (if used) | Create Secrets Manager secrets; use `valueFrom` ARNs in task definitions |
| 5 | **DNS map** | Configure `dns_route_target_groups` (hostname key → svc01–svc07) |

---

## What gets created

| Component | Description |
|-----------|-------------|
| ECS cluster | `${name_prefix}-${environment}-ecs` (override with `cluster_name`) |
| ALB | Internet-facing in **public subnets**; HTTPS + host rules |
| Target groups | Seven (svc01–svc07) |
| ECS services | Fargate in **private subnets**; one task definition per key |
| Route 53 | Alias A records: `{name_prefix}-{key}-{environment}.{domain}` unless `dns_hostnames` overrides |
| Security groups | ALB (ingress 80/443); tasks (ingress from ALB on container ports) |
| IAM | ECS execution role, task role (sample runtime perms), optional deployer user |

---

## Quick start

```bash
# 1. Ensure Phase 1 is applied (see ../../README.md)

# 2. Set ECS state key in repo root backend.hcl
#    key = "ECS-Infrastructure/dev/terraform.tfstate"

cd AWS/ECS-Infrastructure
cp terraform.tfvars.example terraform.tfvars
# Fill: vpc_id, subnets, acm_certificate_arn, images, DNS

terraform init -reconfigure -backend-config=../../backend.hcl
terraform plan
terraform apply
```

---

## DNS hostnames

Default pattern:

```text
{name_prefix}-{dns_key}-{environment}.{route53_domain_name}
```

Example with `name_prefix = "myapp"`, `environment = "dev"`, `route53_domain_name = "example.com"`, and key `api1`:

```text
myapp-api1-dev.example.com
```

Override any host with `dns_hostnames` in `terraform.tfvars`.

---

## Customization

| Variable | Purpose |
|----------|---------|
| `name_prefix` / `environment` | Tags and generated names |
| `service_short_names` | Short names in ECS service / TG resources (svc01 → api1, etc.) |
| `dns_route_target_groups` | DNS key → target group key (svc01–svc07) |
| `dns_hostnames` | Full FQDN overrides |
| `ecs_task_definitions` | CPU, memory, `image`, `container_port`, `secrets` |
| `ecs_services` | `desired_count`, deployment settings per service |
| `cluster_name` / `alb_name` | Optional AWS name overrides |
| `iam_policy_document` | Policy for optional deployer IAM user |

### Secrets in tasks

```hcl
secrets = [
  {
    name      = "DATABASE_URL"
    valueFrom = "arn:aws:secretsmanager:REGION:ACCOUNT:secret:my-secret:DATABASE_URL::"
  }
]
```

JSON secrets require the key suffix (`:KEY::`). Execution role must allow `secretsmanager:GetSecretValue`.

### Task runtime IAM

`modules/ecs_cluster/iam_task.tf` includes **example** permissions (SES, Bedrock, RDS IAM auth). Remove or restrict for your apps.

---

## Outputs

After apply:

```bash
terraform output
```

Includes cluster name, ALB DNS name, target group ARNs, and Route 53 record FQDNs (see `outputs.tf`).

---

## Troubleshooting

| Issue | Check |
|-------|--------|
| Invalid VPC / subnet | Re-run Phase 1; copy fresh outputs; same region |
| Health checks failing | `health_check_path`; app listens on `container_port` |
| 503 from ALB | Listener rules / `dns_route_target_groups` point to correct TG |
| Task fails to start | ECR pull (execution role); secrets ARN and JSON keys |
| Certificate error | ACM in same region as `aws_region` |

---

## Back to Phase 1

VPC, subnets, NAT: **[../../README.md#phase-1-vpc-networking](../../README.md#phase-1-vpc-networking)**
