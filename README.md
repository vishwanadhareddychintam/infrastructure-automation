# Infrastructure Automation

Terraform for AWS in **two phases**: deploy **VPC networking** first, then deploy **applications on an ECS Fargate cluster** (ALB, HTTPS, Route 53). Each phase is a separate Terraform root module with its own state file.

## Deployment flow

```
Prerequisites (once per account)
        │
        ▼
┌───────────────────────┐
│ Phase 1: Networking │  AWS/  — VPC, subnets, NAT, S3 endpoint
└───────────┬───────────┘
            │ outputs: vpc_id, public_subnet_ids, private_subnet_ids
            ▼
┌───────────────────────┐
│ Phase 2: ECS apps     │  AWS/ECS-Infrastructure/  — cluster, ALB, 4 services, DNS
└───────────────────────┘
```

| Phase | Directory | State key (example) | Guide |
|-------|-----------|---------------------|--------|
| 1 — VPC | `AWS/` | `networking/dev/terraform.tfstate` | [Below](#phase-1-vpc-networking) |
| 2 — ECS | `AWS/ECS-Infrastructure/` | `ECS-Infrastructure/dev/terraform.tfstate` | [AWS/ECS-Infrastructure/README.md](AWS/ECS-Infrastructure/README.md) |

---

## Repository layout

```
infrastructure-automation/
├── README.md                 # This file — full deployment guide
├── backend.hcl.example       # Remote state (copy per phase; change key)
└── AWS/
    ├── main.tf               # Phase 1: networking
    ├── terraform.tfvars.example
    ├── modules/networking/
    ├── iampolicies/          # Example IAM policies
    └── ECS-Infrastructure/   # Phase 2: ECS application platform
        ├── README.md
        └── terraform.tfvars.example
```

---

## Prerequisites (before any Terraform)

Complete these **once per AWS account** (or org). Both phases depend on them.

### Tools

| Tool | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads) | >= 1.4 (networking), >= 1.2 (ECS) |
| [AWS CLI](https://aws.amazon.com/cli/) | v2 recommended |

### IAM profile

Terraform needs an identity that can manage resources **and** use remote state (S3 + DynamoDB lock).

**Option A — IAM user**

1. Create a user with programmatic access.
2. Attach policies built from:
   - `AWS/iampolicies/terraform-state-backend.json.example` — state bucket + lock table
   - `AWS/iampolicies/terraform-networking.json.example` — Phase 1
   - `AWS/iampolicies/terraform-ecs.json.example` — Phase 2 (add before ECS apply)
3. Configure CLI profile:

```ini
# ~/.aws/credentials
[terraform-infra]
aws_access_key_id     = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

**Option B — IAM role** (teams / CI): same policies on a role; use `role_arn` + `source_profile` in `~/.aws/config`.

Verify:

```bash
aws sts get-caller-identity --profile terraform-infra
```

Use profile name `terraform-infra` in all `terraform.tfvars` files (or your chosen name — keep it consistent in `provider.tf`, `backend.hcl`, and tfvars).

### S3 remote state + DynamoDB lock

Create once; reuse for every stack and environment.

**S3 bucket** (versioning + encryption + block public access):

```bash
export AWS_PROFILE=terraform-infra
export AWS_REGION=us-east-1
export STATE_BUCKET=my-org-terraform-state

aws s3api create-bucket \
  --bucket "$STATE_BUCKET" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION"

aws s3api put-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block \
  --bucket "$STATE_BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

**DynamoDB lock table** (partition key `LockID`, type String):

```bash
export LOCK_TABLE=my-org-terraform-locks

aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION"
```

**`backend.hcl`** (repo root — copy from `backend.hcl.example`, gitignored):

```hcl
bucket         = "my-org-terraform-state"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "my-org-terraform-locks"
profile        = "terraform-infra"
# key = set per phase below
```

| Phase | `key` in `backend.hcl` |
|-------|-------------------------|
| Networking (dev) | `networking/dev/terraform.tfstate` |
| ECS Infrastructure (dev) | `ECS-Infrastructure/dev/terraform.tfstate` |

Use a **different `key` per phase and environment** so state files do not overwrite each other.

---

## Phase 1: VPC networking

Creates the network foundation ECS runs on.

### What Phase 1 creates

| Resource | Purpose |
|----------|---------|
| VPC | Private address space (`vpc_cidr`) |
| Internet gateway | Internet for public subnets |
| 2× public subnets | ALB (Phase 2) |
| 2× private subnets | ECS tasks (Phase 2) |
| NAT gateway | Outbound internet from private subnets |
| S3 gateway endpoint | Private subnet access to S3 without NAT |

### VPC CIDR examples

Subnets must be inside `vpc_cidr` and must not overlap.

**Dev**

```hcl
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
```

**Staging / prod** — use separate `/16` blocks per environment (e.g. `10.20.0.0/16`, `10.30.0.0/16`).

### Phase 1 — commands

```bash
# From repo root
cp backend.hcl.example backend.hcl
# Edit backend.hcl: bucket, dynamodb_table, key = "networking/dev/terraform.tfstate"

cd AWS
cp terraform.tfvars.example terraform.tfvars
# Edit: aws_profile, name_prefix, environment, vpc_cidr, subnets

terraform init -reconfigure -backend-config=../backend.hcl
terraform plan
terraform apply
```

### Phase 1 — outputs (required for Phase 2)

```bash
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids
```

Save these values for `AWS/ECS-Infrastructure/terraform.tfvars`.

| Output | Used in ECS for |
|--------|------------------|
| `vpc_id` | Security groups, ALB, services |
| `public_subnet_ids` | Internet-facing ALB |
| `private_subnet_ids` | Fargate tasks |

---

## Phase 2: ECS Infrastructure (application deployment)

Run **only after Phase 1 succeeds**. ECS tasks run in **private subnets**; the ALB sits in **public subnets**.

### Prerequisites checklist (Phase 2)

| # | Requirement | Notes |
|---|-------------|--------|
| 1 | Phase 1 applied | `vpc_id` and subnet outputs available |
| 2 | Same `aws_region` | ECS stack region must match VPC |
| 3 | IAM | `terraform-ecs.json.example` attached to Terraform profile |
| 4 | Remote state | `backend.hcl` `key` = `ECS-Infrastructure/<env>/terraform.tfstate` (not networking key) |
| 5 | ACM certificate | HTTPS cert in ALB region for your hostnames |
| 6 | Route 53 | Public hosted zone for `route53_domain_name` |
| 7 | Container images | Images in ECR (or registry) referenced in `ecs_task_definitions` |
| 8 | Secrets (optional) | Secrets Manager / SSM ARNs if tasks use `secrets` |

### What Phase 2 creates

| Component | Description |
|-----------|-------------|
| ECS cluster | Fargate (+ optional Container Insights) |
| ALB | HTTPS, HTTP→HTTPS redirect, host-based routing |
| 4 ECS services | Task definitions + services (customize in tfvars) |
| Target groups | One per service |
| Route 53 | Alias records for app hostnames |
| Security groups | ALB ↔ tasks |

Detailed steps, DNS naming, and troubleshooting: **[AWS/ECS-Infrastructure/README.md](AWS/ECS-Infrastructure/README.md)**.

### Phase 2 — commands

```bash
# Update backend.hcl key for ECS, e.g.:
#   key = "ECS-Infrastructure/dev/terraform.tfstate"

cd AWS/ECS-Infrastructure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_profile = "terraform-infra"
aws_region  = "us-east-1"   # same as VPC

name_prefix = "myapp"
environment = "dev"

# From Phase 1 outputs
vpc_id             = "vpc-xxxxxxxx"
public_subnet_ids  = ["subnet-...", "subnet-..."]
private_subnet_ids = ["subnet-...", "subnet-..."]

acm_certificate_arn   = "arn:aws:acm:..."
route53_domain_name   = "example.com"
# route53_hosted_zone_id = "Z..."  # optional

# ECR images, ports, dns_route_target_groups — see terraform.tfvars.example
```

```bash
terraform init -reconfigure -backend-config=../../backend.hcl
terraform plan
terraform apply
```

---

## Configuration reference

### Phase 1 (`AWS/terraform.tfvars`)

| Variable | Description |
|----------|-------------|
| `aws_profile` | CLI profile (**required**) |
| `aws_region` | Region (default `us-east-1`) |
| `vpc_cidr` | VPC CIDR |
| `public_subnet_cidrs` | Two public subnet CIDRs |
| `private_subnet_cidrs` | Two private subnet CIDRs |
| `name_prefix` | Name/tag prefix (**required**) |
| `environment` | dev / staging / prod (**required**) |

### Phase 2 (`AWS/ECS-Infrastructure/terraform.tfvars`)

See [AWS/ECS-Infrastructure/README.md](AWS/ECS-Infrastructure/README.md#customization).

---

## Troubleshooting

### Phase 1 (VPC)

| Issue | Check |
|-------|--------|
| `AccessDenied` on init | State backend IAM; profile name |
| Subnet CIDR errors | Subnets inside `vpc_cidr`; exactly two per type |
| NAT cost in dev | One NAT per VPC; consider smaller envs |

### Phase 2 (ECS)

| Issue | Check |
|-------|--------|
| Plan fails on VPC/subnets | Phase 1 outputs copied correctly; same region |
| Target group unhealthy | `health_check_path`; SG allows ALB → container port |
| HTTPS / cert errors | ACM ARN in same region as `aws_region` |
| DNS not resolving | Hosted zone; `dns_route_target_groups` |

---

## Extending this repo

- Add modules under `AWS/modules/` or `AWS/ECS-Infrastructure/modules/`.
- Add other clouds as top-level folders (`Azure/`, `GCP/`).
- Change folder names freely — only Terraform `source` paths must match.
