terraform {
  backend "azurerm" {
    subscription_id      = "76729d87-f7f1-4620-a476-83ccd5d9f681"
    resource_group_name  = "shared-storage"
    storage_account_name = "iaccoresharedstgem22"
    container_name       = "tf-state"
    key                  = "terraform-deploy-example/terraform.tfstate"
  }
}
