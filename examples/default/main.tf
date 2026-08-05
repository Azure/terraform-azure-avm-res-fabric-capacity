terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

# Microsoft Fabric capacities are not offered in every Azure region, and Fabric
# capacity-unit (CU) quota is granted per subscription *per region*. Randomising
# the region -- as the Azure/avm-utl-regions module would -- means an apply can
# land in a region where the subscription's Fabric CU limit is 0 and fail before
# it creates anything. The examples therefore pin a single region that has
# default (out-of-the-box) Fabric CU quota, so they deploy without first raising
# a quota-increase request.
# https://learn.microsoft.com/fabric/enterprise/fabric-quotas
locals {
  location = "swedencentral"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

# Fabric capacity names are lowercase alphanumeric only, so a random suffix is
# used instead of the naming module to keep concurrent example runs unique.
resource "random_string" "suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.naming.resource_group.name_unique
}

# The Fabric capacities API accepts an Entra user by UPN, or a service principal
# by object ID -- a user's object ID is rejected. Administering the capacity with
# a purpose-created managed identity keeps the example working whether it is
# applied by a user or by a service principal, and needs no inputs.
resource "azurerm_user_assigned_identity" "fabric_admin" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

module "fabric_capacity" {
  source = "../../"

  location  = azurerm_resource_group.this.location
  name      = "fc${random_string.suffix.result}"
  parent_id = azurerm_resource_group.this.id
  sku_name  = "F2"
  # In a real deployment, supply the UPNs of your capacity administrators.
  administration_members = [azurerm_user_assigned_identity.fabric_admin.principal_id]
  enable_telemetry       = var.enable_telemetry
}