# Microsoft Fabric Capacity

This is an [Azure Verified Module (AVM)](https://aka.ms/avm) **resource module** for **Microsoft Fabric Capacity** (`Microsoft.Fabric/capacities`), built on the **AzAPI** provider. It creates a single Fabric capacity and exposes the AVM resource interfaces that the capacity resource supports.

## Resource Contract

- Resource type: `Microsoft.Fabric/capacities@2023-11-01` by default.
- Parent: existing resource-group resource ID.
- SKU: supported Fabric F SKU with fixed `Fabric` tier.
- Administrators: Entra user UPNs or service-principal object IDs. Entra groups are not accepted by the capacity ARM API.
- Shared interfaces: `Azure/avm-utl-interfaces/azure` v0.6.0 for management locks and ARM role assignments.
- Operations: telemetry, tags, configurable retry behavior, and timeouts.
- Outputs: name, resource ID, provisioning state, and runtime state.

Tenant settings are intentionally excluded. They are tenant-scoped Fabric API resources rather than properties of a capacity, so they belong to a tenant-settings module rather than this one.

## Unsupported AVM extension resources (RMFR4)

[AVM resource-module spec RMFR4](https://azure.github.io/Azure-Verified-Modules/spec/RMFR4) requires resource modules to support `diagnostic_settings`, `role_assignments`, `lock`, `tags`, `managed_identities`, `private_endpoints`, and `customer_managed_key`, where the underlying Azure resource supports them. This module implements `role_assignments`, `lock`, and `tags`. It intentionally does **not** implement `diagnostic_settings`, `managed_identities`, `private_endpoints`, or `customer_managed_key`, because `Microsoft.Fabric/capacities` does not support them:

- **Managed identities** -- the `Microsoft.Fabric/capacities` ARM schema (checked against both the `2023-11-01` GA and `2025-01-15-preview` API versions) has no `identity` block. There is no system-assigned or user-assigned identity to attach.
- **Private endpoints** -- the resource schema exposes no `privateEndpointConnections` or `publicNetworkAccess` property, and Fabric's private-link surface (`Microsoft.Fabric/privateLinkServicesForFabric`) is a workspace-level concept, not a capacity-level one. A capacity cannot itself be the target of a private endpoint.
- **Customer-managed keys** -- the resource schema has no encryption/CMK-related properties.
- **Diagnostic settings** -- Azure Monitor does not publish supported metric or log categories for `Microsoft.Fabric/capacities`, so there is no `Microsoft.Insights/diagnosticSettings` target to wire up.

The published Microsoft-owned Bicep AVM module for the same resource type ([`avm/res/fabric/capacity`](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/fabric/capacity)) corroborates this: it implements only `name`, `location`, `tags`, `sku`, `administration.members`, `lock`, and telemetry -- no identity, private endpoint, CMK, or diagnostic-settings support either.

If a future Fabric capacities API version adds any of these capabilities, this module should be updated to add the corresponding interface at that time.

## Prerequisites

- The `Microsoft.Fabric` resource provider must be registered on the target subscription, or the capacity `PUT` fails with `409 MissingSubscriptionRegistration`. The AzAPI provider registers it for you unless you set `skip_provider_registration = true` (or `ARM_SKIP_PROVIDER_REGISTRATION`); if you do, register it out of band with `az provider register --namespace Microsoft.Fabric`.
- The subscription needs [Fabric capacity-unit (CU) quota](https://learn.microsoft.com/fabric/enterprise/fabric-quotas) in the target region. Quota is granted per subscription **per region**, and most regions start at `0` CUs until a quota-increase request is approved.
- Every principal in `administration_members` must already exist in Entra ID. If you create the principal in the same `terraform apply` -- a new service principal or managed identity, for example -- the Fabric control plane can still reject it with `400 BadRequest / All provided principals must be existing` until Entra ID replicates. Add that message to `retry.error_message_regex`, as the examples do.

> [!NOTE]
> A Fabric capacity bills from the moment it is created until it is deleted or paused, regardless of use. Size the SKU deliberately and pause or delete capacities you are not using.

## Example

```hcl
module "capacity" {
  source  = "Azure/avm-res-fabric-capacity/azure"
  version = "~> 0.1"

  administration_members = ["fabric-admin@contoso.com"]
  location               = "westeurope"
  name                   = "fcsharedprod"
  parent_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-fabric-prod"
  sku_name               = "F64"
  lock                   = { kind = "CanNotDelete" }
}
```

See [examples/default](examples/default) for the simplest runnable configuration, and [examples/max](examples/max) for one exercising every supported AVM interface.

## Validation

This repository uses the standard AVM Terraform tooling, which runs in a container and requires Docker or Podman:

```powershell
./avm pre-commit    # avmfix, terraform fmt, terraform-docs
./avm pr-check      # linting, TFLint (AVM ruleset), Conftest/OPA
./avm tf-test-unit  # mocked unit tests in tests/unit
```
