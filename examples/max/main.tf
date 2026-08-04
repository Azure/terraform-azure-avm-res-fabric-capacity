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

data "azurerm_client_config" "current" {}

# Microsoft Fabric capacities are not offered in every Azure region, so this
# example randomises across a vetted subset rather than using the
# Azure/avm-utl-regions module (which returns every region).
locals {
  fabric_regions = [
    "australiaeast",
    "canadacentral",
    "eastus",
    "eastus2",
    "francecentral",
    "northeurope",
    "southeastasia",
    "swedencentral",
    "uksouth",
    "westeurope",
    "westus2",
    "westus3",
  ]
}

resource "random_integer" "region_index" {
  max = length(local.fabric_regions) - 1
  min = 0
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
  location = local.fabric_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

# A deterministic service principal to receive the role assignment, so the
# example behaves identically whether it is applied by a user or by CI.
resource "azurerm_user_assigned_identity" "this" {
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
  # The Fabric capacities API accepts an Entra user UPN or a service-principal
  # object ID. The deploying identity is used here so the example needs no
  # inputs. In a real deployment, supply the UPNs of your capacity administrators.
  administration_members = [data.azurerm_client_config.current.object_id]
  enable_telemetry       = var.enable_telemetry

  lock = {
    kind = "CanNotDelete"
    name = "lock-fabric-capacity"
  }

  role_assignments = {
    reader = {
      role_definition_id_or_name = "Reader"
      principal_id               = azurerm_user_assigned_identity.this.principal_id
      principal_type             = "ServicePrincipal"
      description                = "Read access to the Fabric capacity for the example workload identity."
      # The identity is created in the same apply, so skip the Entra replication check.
      skip_service_principal_aad_check = true
    }
  }

  retry = {
    error_message_regex = ["409 Conflict", "429 Too Many Requests"]
  }

  timeouts = {
    create = "45m"
    delete = "45m"
    read   = "5m"
    update = "45m"
  }

  tags = {
    environment = "example"
    workload    = "fabric-capacity"
  }
}
