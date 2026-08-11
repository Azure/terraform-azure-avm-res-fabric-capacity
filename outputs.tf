output "name" {
  description = "Name of the Fabric capacity."
  value       = azapi_resource.this.name
}

output "provisioning_state" {
  description = "Provisioning state of the Fabric capacity, e.g. `Succeeded` or `Failed`."
  value       = azapi_resource.this.output.properties.provisioningState
}

output "resource_id" {
  description = "Azure resource ID of the Fabric capacity."
  value       = azapi_resource.this.id
}

output "state" {
  description = "Runtime state of the Fabric capacity, e.g. `Active` or `Paused`. Reported separately from `provisioning_state` because a capacity that provisioned successfully can still be suspended and therefore unusable."
  value       = azapi_resource.this.output.properties.state
}
