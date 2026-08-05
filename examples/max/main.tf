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
  # Microsoft.Fabric is not part of the AzureRM provider's default registration
  # set, so a subscription that has never deployed Fabric rejects the capacity
  # PUT with 409 MissingSubscriptionRegistration. Registering it here blocks
  # until the provider reports Registered, before any resource is created.
  resource_providers_to_register = ["Microsoft.Fabric"]
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

# A deterministic service principal used both to administer the capacity and to
# receive the role assignment, so the example behaves identically whether it is
# applied by a user or by CI. The Fabric capacities API accepts an Entra user by
# UPN, or a service principal by object ID -- a user's object ID is rejected.
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
  # In a real deployment, supply the UPNs of your capacity administrators.
  administration_members = [azurerm_user_assigned_identity.this.principal_id]
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
