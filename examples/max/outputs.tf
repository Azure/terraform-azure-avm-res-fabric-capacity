output "location" {
  description = "Azure region of the Fabric capacity."
  value       = module.fabric_capacity.location
}

output "name" {
  description = "Name of the Fabric capacity."
  value       = module.fabric_capacity.name
}

output "resource_id" {
  description = "Resource ID of the Fabric capacity."
  value       = module.fabric_capacity.resource_id
}
