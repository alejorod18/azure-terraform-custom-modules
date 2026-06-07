terraform {
  required_version = ">= 1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.16"
    }
  }
}

provider "azurerm" {
  subscription_id = "<your-azure-subscription-id>"
  features {}
}
