data "azapi_client_config" "current" {}

module "interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  enable_telemetry                 = var.enable_telemetry
  lock                             = var.lock
  role_assignment_definition_scope = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  role_assignments                 = var.role_assignments
}

resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.fabric_capacities
  body = {
    properties = {
      administration = {
        members = sort(tolist(var.administration_members))
      }
    }
    sku = {
      name = var.sku_name
      tier = "Fabric"
    }
  }
  create_headers        = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers        = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_refs = []
  # Only the read-only attributes exposed as outputs. Exporting the whole response
  # would persist the administration members and SKU in state for no benefit.
  response_export_values = [
    "properties.provisioningState",
    "properties.state",
  ]
  retry          = var.retry
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name                   = coalesce(module.interfaces.lock_azapi.name, "lock-${var.lock.kind}")
  parent_id              = azapi_resource.this.id
  type                   = module.interfaces.lock_azapi.type
  body                   = module.interfaces.lock_azapi.body
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }

  # A `CanNotDelete` lock on the capacity also blocks deletes of anything scoped
  # to it, including its role assignments. Terraform destroys in reverse creation
  # order, so creating the lock *after* the role assignments makes it the first
  # thing destroyed. Without this the lock, the role assignments and the capacity
  # delete concurrently and race, and every loser of that race comes back as
  # `409 ScopeLocked`.
  depends_on = [azapi_resource.role_assignments]
}

resource "azapi_resource" "role_assignments" {
  for_each = module.interfaces.role_assignments_azapi

  name                   = each.value.name
  parent_id              = azapi_resource.this.id
  type                   = each.value.type
  body                   = each.value.body
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = []
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    create = var.timeouts.create
    delete = var.timeouts.delete
    read   = var.timeouts.read
    update = var.timeouts.update
  }
}
