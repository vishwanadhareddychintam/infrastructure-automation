terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Override via backend.hcl at init (see README):
  #   terraform init -reconfigure -backend-config=../backend.hcl
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "YOUR_TFSTATE_STORAGE_ACCOUNT"
    container_name       = "tfstate"
    key                  = "azure/networking/dev.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
}
