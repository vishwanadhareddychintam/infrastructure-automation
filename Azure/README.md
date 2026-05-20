# Azure infrastructure

Two-phase Terraform aligned with the [AWS stacks](../README.md): **networking (VNet)** first, then **Container Apps + Application Gateway**.

## Deployment flow

```
Prerequisites (Azure AD, state storage, RBAC)
        │
        ▼
┌────────────────────────────┐
│ Phase 1: Networking        │  Azure/  — VNet, NAT, NSGs, ACA subnet, App GW subnet
└─────────────┬──────────────┘
              │ outputs: subnet IDs, Log Analytics, App Gateway public IP
              ▼
┌────────────────────────────┐
│ Phase 2: Container Apps    │  Azure/Container-Apps-Infrastructure/
└────────────────────────────┘
```

| Phase | Directory | State key (example) |
|-------|-----------|---------------------|
| 1 | `Azure/` | `azure/networking/dev.terraform.tfstate` |
| 2 | `Azure/Container-Apps-Infrastructure/` | `azure/container-apps/dev.terraform.tfstate` |

## AWS ↔ Azure mapping

| AWS (this repo) | Azure (this folder) |
|-----------------|---------------------|
| VPC | Virtual Network |
| Public / private subnets | Subnets + NSGs + route tables |
| NAT Gateway | NAT Gateway + public IP |
| S3 gateway endpoint | (optional) Storage private endpoint — add when needed |
| ECS Fargate + ALB | Container Apps (internal ingress) + Application Gateway WAF_v2 |
| Route 53 | Azure DNS A records |
| IAM roles | User-assigned managed identity + RBAC |
| Secrets Manager | Key Vault (certificate for App Gateway HTTPS) |

## Prerequisites

### Tools

- Terraform >= 1.4
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az login`)

### Authentication

```bash
az login
az account set --subscription "<subscription-id>"
```

Optional: set `subscription_id` in `terraform.tfvars` or `ARM_SUBSCRIPTION_ID`.

### Remote state (azurerm backend)

Create once per organization:

1. Resource group `rg-terraform-state`
2. Storage account (globally unique name, e.g. `myorgtfstate`)
3. Container `tfstate`

```bash
az group create --name rg-terraform-state --location eastus
az storage account create --name myorgtfstate --resource-group rg-terraform-state --sku Standard_LRS
az storage container create --name tfstate --account-name myorgtfstate
```

Copy `backend.hcl.example` at repo root (Azure section) or set values in `provider.tf` and run:

```bash
cd Azure
terraform init -reconfigure -backend-config=../backend.hcl
```

### RBAC for Terraform

Assign **Contributor** (or a custom role) on the subscription or target resource groups to the principal running Terraform. For state storage, **Storage Blob Data Contributor** on the container.

See `iampolicies/` for example custom role JSON.

## Phase 1 — Networking

### Creates

- Resource group `{name_prefix}-{environment}-rg`
- VNet with public, private, **Container Apps** (`/23` delegated), and **dedicated Application Gateway** subnet
- NAT Gateway for private/ACA outbound traffic
- NSGs (public allows 80/443; private denies direct internet inbound)
- Log Analytics workspace (used by Container Apps in Phase 2)

### Commands

```bash
cd Azure
cp terraform.tfvars.example terraform.tfvars
# Edit: location, name_prefix, environment, address prefixes

terraform init -reconfigure -backend-config=../backend.hcl
terraform plan
terraform apply
```

### Outputs for Phase 2

```bash
terraform output resource_group_name
terraform output container_apps_subnet_id
terraform output log_analytics_workspace_id
terraform output app_gateway_subnet_id
terraform output app_gateway_public_ip_id
terraform output app_gateway_public_ip_address
```

## Phase 2 — Container Apps

See **[Container-Apps-Infrastructure/README.md](Container-Apps-Infrastructure/README.md)**.

## Address space example (dev)

| Subnet | CIDR | Purpose |
|--------|------|---------|
| VNet | `10.0.0.0/16` | Address space |
| public-1/2 | `10.0.1.0/24`, `10.0.2.0/24` | Future public workloads |
| private-1/2 | `10.0.3.0/24`, `10.0.4.0/24` | Private workloads |
| aca | `10.0.8.0/23` | Container Apps Environment (delegated) |
| appgw | `10.0.16.0/24` | Application Gateway only |

## Troubleshooting

| Issue | Check |
|-------|--------|
| ACA subnet error | Prefix must be `/23` or larger; delegation `Microsoft.App/environments` |
| App Gateway subnet | Must not contain resources other than App Gateway |
| `az login` / subscription | `az account show`; `subscription_id` in tfvars |
