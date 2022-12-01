provider "azurerm" {
  #skip_provider_registration = "true"
  features {}
}

terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.1"
    }
  }
}