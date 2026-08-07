mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000001"
      tenant_id       = "00000000-0000-0000-0000-000000000002"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  administration_members = ["fabric-admin@example.com"]
  location               = "westeurope"
  name                   = "fctest"
  parent_id              = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rg-fabric-test"
  sku_name               = "F2"
}

run "capacity_contract" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.sku.tier == "Fabric"
    error_message = "The capacity must use the Fabric tier."
  }

  assert {
    condition     = azapi_resource.this.body.properties.administration.members[0] == "fabric-admin@example.com"
    error_message = "The capacity must preserve its administrator identity."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Fabric/capacities@2023-11-01"
    error_message = "The capacity must use the approved stable ARM API by default."
  }
}

run "lock_and_telemetry_controls" {
  command = plan

  variables {
    enable_telemetry = false
    lock             = { kind = "CanNotDelete" }
  }

  assert {
    condition     = length(azapi_resource.lock) == 1
    error_message = "A requested capacity lock must be created."
  }

  assert {
    condition     = length(modtm_telemetry.telemetry) == 0
    error_message = "Disabling telemetry must prevent telemetry resource creation."
  }
}

run "rejects_group_object_id_claim" {
  command = plan

  variables {
    administration_members = ["not-a-upn-or-service-principal-id"]
  }

  expect_failures = [var.administration_members]
}

run "rejects_invalid_sku" {
  command = plan

  variables {
    sku_name = "P1"
  }

  expect_failures = [var.sku_name]
}