terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.53.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "example" {
  name     = "example-rgrp"
  location = "West Europe"
}

resource "azurerm_resource_group" "example_2" {
  name     = "example-rgrp-2"
  location = "West Europe"
}