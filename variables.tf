variable "administration_members" {
  type        = set(string)
  description = "Fabric capacity administrators. Use a user principal name for an Entra user or an object ID for a service principal."
  nullable    = false

  validation {
    condition = length(var.administration_members) > 0 && alltrue([
      for member in var.administration_members :
      can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", member)) ||
      can(regex("(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$", member))
    ])
    error_message = "administration_members must contain at least one Entra user UPN or service-principal object ID."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the Fabric capacity."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Name of the Fabric capacity."
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,62}$", var.name))
    error_message = "name must be 3-63 lowercase letters or numbers and start with a lowercase letter."
  }
}

variable "parent_id" {
  type        = string
  description = "Resource ID of the resource group in which to create the Fabric capacity."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "parent_id must be a valid resource-group resource ID."
  }
}

variable "sku_name" {
  type        = string
  description = "Fabric F SKU for the capacity."
  nullable    = false

  validation {
    condition     = contains(["F2", "F4", "F8", "F16", "F32", "F64", "F128", "F256", "F512", "F1024", "F2048"], var.sku_name)
    error_message = "sku_name must be a supported Fabric F SKU."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for the Fabric capacity. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock == null || contains(["CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "Lock kind must be one of: `CanNotDelete` or `ReadOnly`."
  }
}

variable "resource_types" {
  type = object({
    fabric_capacities = optional(string, "Microsoft.Fabric/capacities@2023-11-01")
  })
  default     = {}
  description = "AzAPI resource types used by this module. Override only when validating a supported API migration."
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["409 Conflict", "429 Too Many Requests"])
    interval_seconds     = optional(number, null)
    max_interval_seconds = optional(number, null)
  })
  default     = {}
  description = "Retry configuration for AzAPI resource operations."
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of **Azure RBAC (control-plane)** role assignments to create on the Fabric capacity. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Microsoft Entra check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Valid values are `2.0`.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource ID which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`.
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Map of tags to assign to the Fabric capacity resource."
}

variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    delete = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
  })
  default     = {}
  description = "Timeouts for Fabric capacity, lock, and role-assignment operations."
  nullable    = false
}
