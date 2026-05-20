# ECS on Fargate (ALB + Route 53)

Deploys seven ECS Fargate services behind one internet-facing Application Load Balancer with HTTPS, Route 53 aliases, security groups, and optional IAM deployer user.

**Prerequisite:** VPC with public and private subnets — apply the [networking stack](../) first and copy its outputs into `terraform.tfvars`.

## What gets created

| Component | Description |
|-----------|-------------|
| ECS cluster | Fargate with optional Container Insights |
| ALB | HTTPS (ACM cert), HTTP→HTTPS redirect, host-based routing |
| Target groups | Seven (svc01–svc07), one per service |
| ECS services | Seven task definitions + services in private subnets |
| Route 53 | Alias A records per `dns_route_target_groups` |
| Security groups | ALB (public) and ECS tasks (private) |
| IAM | Task execution role, task role (SES/Bedrock/RDS IAM auth examples), optional deployer user |

## Setup order

### 1. IAM profile

Use the same profile as the networking stack (`terraform-infra` in examples).

Attach policies from:

- `../iampolicies/terraform-state-backend.json.example` — S3 state + DynamoDB lock
- `../iampolicies/terraform-ecs.json.example` — ECS, ALB, ECR, Route 53 (tighten for production)

```bash
aws sts get-caller-identity --profile terraform-infra
```

### 2. Remote state

Use a **different state key** than networking, e.g. in `backend.hcl` at repo root:

```hcl
key = "ecs/dev/terraform.tfstate"
```

```bash
cd AWS/ecs
terraform init -reconfigure -backend-config=../../backend.hcl
```

### 3. ACM certificate

Request or import a certificate in **the same region** as the ALB for your hostnames (wildcard `*.example.com` or per-host).

Set `acm_certificate_arn` in `terraform.tfvars`.

### 4. Route 53

- Public hosted zone for `route53_domain_name`
- Set `route53_hosted_zone_id` or leave null to look up the zone by name

Auto hostnames (unless overridden in `dns_hostnames`):

`{name_prefix}-{dns_key}-{environment}.{route53_domain_name}`

Example: `myapp-api1-dev.example.com`

### 5. Container images

Push images to ECR (or use another registry) and set `image` in each `ecs_task_definitions` entry.

**Secrets:** optional `secrets` list per task — `valueFrom` must be a Secrets Manager or SSM ARN (`arn:...:secret:name:KEY::` for JSON keys).

### 6. Configure and apply

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit: vpc_id, subnets, acm_certificate_arn, images, dns_route_target_groups

terraform plan
terraform apply
```

## Wiring from networking stack

From `AWS/` (networking):

```bash
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids
```

Paste into `ecs/terraform.tfvars`.

## Customization

| Variable | Purpose |
|----------|---------|
| `name_prefix` / `environment` | Tags and generated names |
| `service_short_names` | Labels in ECS service and TG names (svc01→api1, etc.) |
| `dns_route_target_groups` | Which hostname maps to which service |
| `dns_hostnames` | Full FQDN overrides |
| `cluster_name` / `alb_name` | Override AWS resource names |
| `ecs_task_definitions` | CPU, memory, image, ports, secrets |
| `iam_policy_document` | Policy for optional deployer IAM user |

## Task IAM (runtime)

The default task role in `modules/ecs_cluster/iam_task.tf` includes example permissions for SES, Bedrock, and RDS IAM DB auth. Remove or narrow statements for your workloads.

## Outputs

Run `terraform output` after apply for cluster name, ALB DNS, target group ARNs, Route 53 records, and IAM user ARN (if created).

## Troubleshooting

| Issue | Check |
|-------|--------|
| Health check failures | `health_check_path` matches your app; security group allows ALB → task port |
| Certificate error | ACM ARN region matches `aws_region` |
| Secrets fail at start | Execution role can `secretsmanager:GetSecretValue`; JSON key exists in secret |
| DNS not resolving | Hosted zone ID correct; alias points to ALB |
