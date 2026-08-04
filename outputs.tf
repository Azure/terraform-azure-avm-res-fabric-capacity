output "location" {
  description = "Azure region of the Fabric capacity."
  value       = azapi_resource.this.location
}

output "name" {
  description = "Name of the Fabric capacity."
  value       = azapi_resource.this.name
}

output "resource" {
  description = "The Fabric capacity resource, limited to the exported read-only values (`id`, `location`, `name`, `properties`, `sku`)."
  value       = azapi_resource.this.output
}

output "resource_id" {
  description = "Azure resource ID of the Fabric capacity."
  value       = azapi_resource.this.id
}
