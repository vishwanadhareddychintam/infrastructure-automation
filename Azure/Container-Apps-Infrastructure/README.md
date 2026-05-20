# Phase 2 — Azure Container Apps Infrastructure

Runs **after** [Phase 1 networking](../README.md). Deploys four container apps on Azure Container Apps with **internal ingress**, fronted by **Application Gateway (WAF_v2)** and **Azure DNS** — aligned with AWS ECS + ALB + Route 53.

## Prerequisites checklist

| # | Requirement | Source |
|---|-------------|--------|
| 1 | Phase 1 applied | `Azure/` outputs |
| 2 | Same `location` / region | Match networking stack |
| 3 | Key Vault certificate | Wildcard or SAN cert for your hostnames; secret ID for App Gateway |
| 4 | App Gateway → Key Vault access | Grant App Gateway managed identity **GET** on secrets (see Microsoft docs) |
| 5 | Public DNS zone | `dns_zone_name` + `dns_zone_resource_group_name` |
| 6 | Container images | MCR, Docker Hub, or ACR (`acr_login_server` + `acr_resource_id`) |
| 7 | Remote state | Separate `backend.hcl` key, e.g. `azure/container-apps/dev.terraform.tfstate` |

### Phase 1 values → `terraform.tfvars`

| Phase 1 output | Variable |
|----------------|----------|
| `container_apps_subnet_id` | `container_apps_subnet_id` |
| `log_analytics_workspace_id` | `log_analytics_workspace_id` |
| `app_gateway_subnet_id` | `app_gateway_subnet_id` |
| `app_gateway_public_ip_id` | `app_gateway_public_ip_id` |
| `app_gateway_public_ip_address` | `app_gateway_public_ip_address` |

## What gets created

| Resource | Role |
|----------|------|
| Resource group | `{name_prefix}-{environment}-apps-rg` |
| User-assigned identity | Pull from ACR; runtime identity |
| Container Apps Environment | VNet-integrated (Phase 1 ACA subnet) |
| 4× Container App | Internal HTTP ingress (svc01–svc04) |
| Application Gateway | HTTPS per hostname, WAF optional |
| DNS A records | Point to App Gateway public IP |

Public hostname pattern (default):

```text
{name_prefix}-{dns_key}-{environment}.{dns_zone_name}
```

## Quick start

```bash
# backend.hcl key = "azure/container-apps/dev.terraform.tfstate"

cd Azure/Container-Apps-Infrastructure
cp terraform.tfvars.example terraform.tfvars
# Fill Phase 1 outputs, Key Vault cert secret ID, DNS zone, images

terraform init -reconfigure -backend-config=../../backend.hcl
terraform plan
terraform apply
```

## Key Vault HTTPS certificate

Application Gateway requires a certificate from Key Vault:

1. Import or create a certificate in Key Vault.
2. Note the **secret ID** (not certificate ID) for `key_vault_certificate_secret_id`.
3. Enable App Gateway managed identity and grant:

   - Key Vault: **GET** on secrets
   - Or access policy / RBAC role **Key Vault Secrets User**

## Customization

| Variable | Purpose |
|----------|---------|
| `container_app_definitions` | Four apps: image, CPU, memory, port, probes |
| `dns_route_container_apps` | DNS logical name → svc01–svc04 |
| `service_short_names` | Short names in resource naming |
| `enable_waf` | WAF_v2 vs Standard_v2 SKU |
| `default_container_app_key` | Default HTTPS listener for HTTP redirect |

## Back to Phase 1

[Azure networking README](../README.md#phase-1--networking)
