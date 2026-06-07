terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.16"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.11.0"
    }
  }
}
