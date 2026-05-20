# Azure remote state RBAC

Grant the Terraform principal these roles on the state resource group / storage account:

| Role | Scope | Purpose |
|------|--------|---------|
| **Storage Blob Data Contributor** | Storage account or `tfstate` container | Read/write state blobs |
| **Contributor** (or custom) | Subscription or workload RGs | Manage networking and Container Apps |

Example CLI:

```bash
az role assignment create \
  --assignee "<terraform-sp-object-id>" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<sub>/resourceGroups/rg-terraform-state/providers/Microsoft.Storage/storageAccounts/myorgtfstate"

az role assignment create \
  --assignee "<terraform-sp-object-id>" \
  --role "Contributor" \
  --scope "/subscriptions/<sub>"
```

Tighten scopes to specific resource groups in production.
