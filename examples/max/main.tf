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

resource "azapi_resource" "resource_group" {
  location               = local.location
  name                   = module.naming.resource_group.name_unique
  parent_id              = data.azapi_client_config.current.subscription_resource_id
  type                   = "Microsoft.Resources/resourceGroups@2025-04-01"
  replace_triggers_refs  = []
  response_export_values = []
}

# A deterministic service principal used both to administer the capacity and to
# receive the role assignment, so the example behaves identically whether it is
# applied by a user or by CI. The Fabric capacities API accepts an Entra user by
# UPN, or a service principal by object ID -- a user's object ID is rejected.
resource "azapi_resource" "user_assigned_identity" {
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
  administration_members = [azapi_resource.user_assigned_identity.output.properties.principalId]
  enable_telemetry       = var.enable_telemetry

  lock = {
    kind = "CanNotDelete"
    name = "lock-fabric-capacity"
  }

  role_assignments = {
    reader = {
      role_definition_id_or_name = "Reader"
      principal_id               = azapi_resource.user_assigned_identity.output.properties.principalId
      principal_type             = "ServicePrincipal"
      description                = "Read access to the Fabric capacity for the example workload identity."
      # The identity is created in the same apply, so skip the Entra replication check.
      skip_service_principal_aad_check = true
    }
  }

  # The managed identity's service principal is created in this same apply, and the
  # Fabric control plane rejects it with `400 BadRequest / All provided principals
  # must be existing` until Entra ID has replicated it. Retrying absorbs that.
  # Never match on `409 Conflict` here -- MissingSubscriptionRegistration is a 409,
  # and swallowing it stops AzAPI from auto-registering Microsoft.Fabric.
  retry = {
    error_message_regex = ["All provided principals must be existing"]
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

