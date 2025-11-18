terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.53.0"
    }
  }
}

provider "azurerm" {
  # subscription_id will be automatically determined from the authenticated context
  # (Managed Identity in GitHub Actions)
}

resource "azurerm_resource_group" "example" {
  name     = "example-rgrp"
  location = "West Europe"
}