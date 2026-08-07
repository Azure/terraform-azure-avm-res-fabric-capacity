# Microsoft Fabric Capacity

This is an [Azure Verified Module (AVM)](https://aka.ms/avm) **resource module** for **Microsoft Fabric Capacity** (`Microsoft.Fabric/capacities`), built on the **AzAPI** provider. It creates a single Fabric capacity and exposes the AVM resource interfaces that the capacity resource supports.

## Resource Contract

- Resource type: `Microsoft.Fabric/capacities@2023-11-01` by default.
- Parent: existing resource-group resource ID.
- SKU: supported Fabric F SKU with fixed `Fabric` tier.
- Administrators: Entra user UPNs or service-principal object IDs. Entra groups are not accepted by the capacity ARM API.
- Shared interfaces: `Azure/avm-utl-interfaces/azure` v0.6.0 for management locks and ARM role assignments.
- Operations: telemetry, tags, configurable retry behavior, and timeouts.
- Outputs: name, location, resource ID, and the exported read-only resource body.

Tenant settings are intentionally excluded. They are tenant-scoped Fabric API resources rather than properties of a capacity, so they belong to a tenant-settings module rather than this one.

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
