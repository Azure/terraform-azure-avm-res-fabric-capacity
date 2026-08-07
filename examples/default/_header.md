# Default example

This deploys the module in its simplest form: a single F2 Microsoft Fabric capacity in a new resource group, administered by a purpose-created user-assigned managed identity.

## Why the `retry` block?

The managed identity that administers the capacity is created in the same `terraform apply`. Entra ID replicates its service principal asynchronously, so the Fabric control plane can still reject it with `400 BadRequest / All provided principals must be existing` when the capacity is created moments later. Adding that message to `retry.error_message_regex` lets AzAPI retry the `PUT` until replication catches up.

The `Microsoft.Fabric` resource provider needs no such handling -- the AzAPI provider registers resource providers automatically unless `skip_provider_registration` is set.

## Why Sweden Central?

The example pins `swedencentral` rather than randomising a region.

Fabric [capacity-unit (CU) quota](https://learn.microsoft.com/fabric/enterprise/fabric-quotas) is granted **per subscription, per region**. A subscription that has never used Fabric shows a limit of `0` CUs in most regions, and `Microsoft.Fabric/capacities` fails to create there until a quota-increase request is approved. Randomising the region — as `Azure/avm-utl-regions` does — makes the example fail intermittently for that reason alone, and Fabric capacities are not offered in every region either.

Sweden Central carries default, out-of-the-box Fabric CU quota, so `terraform apply` succeeds on a fresh subscription with no quota request. Change `local.location` to any region where you hold Fabric quota; check yours in **Azure portal → Quotas → Microsoft Fabric**, or with the [Fabric Capacities - List Usages](https://learn.microsoft.com/rest/api/microsoftfabric/fabric-capacities/list-by-subscription) API.
