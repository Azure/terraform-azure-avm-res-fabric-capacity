terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
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

data "azapi_client_config" "current" {}

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

# Microsoft.Fabric is not registered on a subscription by default, so one that has
# never deployed Fabric rejects the capacity PUT with 409
# MissingSubscriptionRegistration. The registration POST returns as soon as it is
# accepted rather than when the provider reaches Registered, so the module call
# below also retries on that error.
resource "azapi_resource_action" "register_fabric" {
  resource_id            = "${data.azapi_client_config.current.subscription_resource_id}/providers/Microsoft.Fabric"
  type                   = "Microsoft.Resources/providers@2021-04-01"
  action                 = "register"
  method                 = "POST"
  response_export_values = []
}

resource "azapi_resource" "resource_group" {
  location               = local.location
  name                   = module.naming.resource_group.name_unique
  parent_id              = data.azapi_client_config.current.subscription_resource_id
  type                   = "Microsoft.Resources/resourceGroups@2025-04-01"
  replace_triggers_refs  = []
  response_export_values = []
}

# The Fabric capacities API accepts an Entra user by UPN, or a service principal
# by object ID -- a user's object ID is rejected. Administering the capacity with
# a purpose-created managed identity keeps the example working whether it is
# applied by a user or by a service principal, and needs no inputs.
resource "azapi_resource" "fabric_admin" {
  location               = azapi_resource.resource_group.location
  name                   = module.naming.user_assigned_identity.name_unique
  parent_id              = azapi_resource.resource_group.id
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30"
  replace_triggers_refs  = []
  response_export_values = ["properties.principalId"]
}

module "fabric_capacity" {
  source = "../../"

  location  = azapi_resource.resource_group.location
  name      = "fc${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  sku_name  = "F2"
  # In a real deployment, supply the UPNs of your capacity administrators.
  administration_members = [azapi_resource.fabric_admin.output.properties.principalId]
  enable_telemetry       = var.enable_telemetry
  retry = {
    error_message_regex = ["409 Conflict", "429 Too Many Requests", "MissingSubscriptionRegistration"]
  }

  depends_on = [azapi_resource_action.register_fabric]
}
