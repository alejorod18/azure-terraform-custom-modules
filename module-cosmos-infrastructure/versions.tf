terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.16"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}
