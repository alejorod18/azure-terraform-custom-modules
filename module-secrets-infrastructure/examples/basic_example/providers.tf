terraform {
  required_version = ">= 1.2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "<your-azure-subscription-id>"
  features {}
}

provider "github" {
  token = var.github_token
  owner = "<your-github-username>"
}