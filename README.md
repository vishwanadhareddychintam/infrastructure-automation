# Infrastructure Automation

Reusable Terraform for AWS networking (VPC, subnets, NAT, S3 gateway endpoint). Clone this repo, configure your AWS account once, then deploy per environment.

## Repository layout

```
infrastructure-automation/
├── README.md
├── backend.hcl.example          # Remote state overrides (copy to backend.hcl)
├── policies/
│   └── terraform-state-backend.json.example
└── AWS/
    ├── main.tf
    ├── provider.tf
    ├── variables.tf
    ├── terraform.tfvars.example # Copy to terraform.tfvars
    ├── outputs.tf
    └── modules/networking/
```

## What gets created

| Resource | Details |
|----------|---------|
| VPC | DNS enabled; size from `vpc_cidr` |
| Internet gateway | Public internet access for public subnets |
| Subnets | 2 public + 2 private (one of each per AZ) |
| NAT gateway | One NAT; private subnets use it for `0.0.0.0/0` |
| Route tables | Public → IGW; private → NAT |
| VPC endpoint | S3 gateway endpoint on private route tables |

Names and tags use `{name_prefix}-{environment}` (e.g. `myapp-dev`).

---

## 1. IAM profile setup

Terraform needs an AWS identity that can manage VPC resources **and** read/write remote state (S3 + DynamoDB lock).

### Option A — IAM user (simplest for individuals)

1. In **IAM → Users → Create user**, enable programmatic access.
2. Attach a policy that includes:
   - VPC/networking permissions for this stack (see `policies/terraform-networking.json.example` if you add it, or use a scoped custom policy).
   - State backend permissions from `policies/terraform-state-backend.json.example` (adjust bucket name and table name).
3. Save the **Access key ID** and **Secret access key**.

### Option B — IAM role (teams / CI)

1. Create a role (e.g. `terraform-infra`) with a trust policy for your user, SSO, or CI OIDC.
2. Attach the same policies as above.
3. Use `aws configure` or `source_profile` + `role_arn` in `~/.aws/config` to assume the role.

### AWS CLI profile

Add to `~/.aws/credentials` (Windows: `%UserProfile%\.aws\credentials`):

```ini
[terraform-infra]
aws_access_key_id     = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

For a role-based profile in `~/.aws/config`:

```ini
[profile terraform-infra]
role_arn       = arn:aws:iam::123456789012:role/terraform-infra
source_profile = your-sso-or-base-profile
region         = us-east-1
```

Verify:

```bash
aws sts get-caller-identity --profile terraform-infra
```

Use the **same profile name** in:

- `AWS/provider.tf` → `backend "s3" { profile = "..." }` and `provider "aws" { profile = ... }`
- `AWS/main.tf` → `provider "aws" { profile = var.aws_profile }`
- `backend.hcl` is optional; backend `profile` in `provider.tf` must match your CLI profile

Set the profile in `AWS/terraform.tfvars`:

```hcl
aws_profile = "terraform-infra"
```

---

## 2. S3 backend setup (remote state)

Create these **once per AWS account** (or per organization), then reuse for every project/environment.

### S3 bucket

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

Use a **unique bucket name** globally. Pick a region and stick with it for the bucket and DynamoDB table.

### DynamoDB lock table

Terraform needs a table with partition key `LockID` (String):

```bash
export LOCK_TABLE=my-org-terraform-locks

aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION"
```

### Wire backend into this project

1. Copy `backend.hcl.example` → `backend.hcl` (add `backend.hcl` to `.gitignore` if it contains account-specific names).
2. Set `bucket`, `key`, `region`, `dynamodb_table`, and optionally `profile`.
3. Update `AWS/provider.tf` backend block defaults to match, or rely entirely on `backend.hcl` at init.

Example `backend.hcl`:

```hcl
bucket         = "my-org-terraform-state"
key            = "networking/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "my-org-terraform-locks"
profile        = "terraform-infra"
```

Use a **unique `key` per stack and environment**, e.g.:

| Stack / env | Suggested state key |
|-------------|---------------------|
| Dev networking | `networking/dev/terraform.tfstate` |
| Prod networking | `networking/prod/terraform.tfstate` |
| Another app | `myapp/staging/terraform.tfstate` |

4. Copy `policies/terraform-state-backend.json.example` and replace `YOUR_STATE_BUCKET` and `YOUR_LOCK_TABLE`, then attach to your IAM user/role.

---

## 3. VPC CIDR examples

Subnets must sit **inside** `vpc_cidr` and must **not overlap** each other. Use private RFC1918 ranges; avoid clashes with on-prem VPN or peered VPCs.

### Small dev (single team)

```hcl
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
```

### Staging (separate /16 from dev)

```hcl
vpc_cidr = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
```

### Production (larger subnets if you expect more ENIs)

```hcl
vpc_cidr = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.0.0/24", "10.2.1.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24"]
```

### Multi-environment in one account (non-overlapping VPCs)

| Environment | `vpc_cidr`     | Public subnets        | Private subnets       |
|-------------|----------------|------------------------|------------------------|
| dev         | `10.10.0.0/16` | `.0.0/24`, `.1.0/24`  | `.2.0/24`, `.3.0/24`  |
| staging     | `10.20.0.0/16` | `.0.0/24`, `.1.0/24`  | `.2.0/24`, `.3.0/24`  |
| prod        | `10.30.0.0/16` | `.0.0/24`, `.1.0/24`  | `.2.0/24`, `.3.0/24`  |

Copy `AWS/terraform.tfvars.example` → `AWS/terraform.tfvars` and edit for your environment.

---

## Quick start (after setup above)

```bash
cd AWS
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: aws_profile, name_prefix, environment, CIDRs

cd ..
cp backend.hcl.example backend.hcl
# Edit backend.hcl: bucket, key, dynamodb_table, profile

cd AWS
terraform init -reconfigure -backend-config=../backend.hcl
terraform plan
terraform apply
```

### Outputs

- `vpc_id`
- `public_subnet_ids`, `private_subnet_ids`
- `nat_gateway_id`

---

## Configuration reference

| Variable | Description |
|----------|-------------|
| `aws_profile` | AWS CLI profile name (**required** in tfvars) |
| `aws_region` | Region (default `us-east-1`) |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_cidrs` | Exactly two public subnet CIDRs |
| `private_subnet_cidrs` | Exactly two private subnet CIDRs |
| `name_prefix` | Resource name prefix (**required**) |
| `environment` | Environment suffix: dev, staging, prod (**required**) |

---

## Adding more infrastructure

- New AWS modules: `AWS/modules/<name>/`, reference from `AWS/main.tf`.
- Other clouds: add top-level folders (`Azure/`, `GCP/`, etc.) with their own README.

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| `AccessDenied` on `terraform init` | IAM policy for S3 bucket + DynamoDB `LockID` table; profile name matches |
| `Error acquiring state lock` | Stale lock in DynamoDB or another user running apply |
| Subnet CIDR errors | Subnets must be inside `vpc_cidr`; lists must have exactly two CIDRs each |
| NAT costs | One NAT gateway per VPC; remove or use NAT instances if cost-sensitive in dev |
