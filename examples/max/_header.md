# Max example

This deploys the module exercising every AVM interface the `Microsoft.Fabric/capacities` resource supports:

- a **resource lock** (`CanNotDelete`);
- a **control-plane Azure RBAC** role assignment (`Reader`) granted to a user-assigned managed identity;
- **tags**;
- explicit **retry** and **timeouts** configuration.

Diagnostic settings, managed identities, private endpoints and customer-managed keys are intentionally absent — the Fabric capacities resource does not support them. See the [module notes](../../README.md#notes) for the evidence behind each exclusion.

## Why the `retry` block?

The managed identity that administers the capacity is created in the same `terraform apply`. Entra ID replicates its service principal asynchronously, so the Fabric control plane can still reject it with `400 BadRequest / All provided principals must be existing` when the capacity is created moments later. Adding that message to `retry.error_message_regex` lets AzAPI retry the `PUT` until replication catches up — the same reason the role assignment sets `skip_service_principal_aad_check`.

The `Microsoft.Fabric` resource provider needs no such handling — the AzAPI provider registers resource providers automatically unless `skip_provider_registration` is set.

## Why Sweden Central?

The example pins `swedencentral` rather than randomising a region.

Fabric [capacity-unit (CU) quota](https://learn.microsoft.com/fabric/enterprise/fabric-quotas) is granted **per subscription, per region**. A subscription that has never used Fabric shows a limit of `0` CUs in most regions, and `Microsoft.Fabric/capacities` fails to create there until a quota-increase request is approved. Randomising the region — as `Azure/avm-utl-regions` does — makes the example fail intermittently for that reason alone, and Fabric capacities are not offered in every region either.

Sweden Central carries default, out-of-the-box Fabric CU quota, so `terraform apply` succeeds on a fresh subscription with no quota request. Change `local.location` to any region where you hold Fabric quota; check yours in **Azure portal → Quotas → Microsoft Fabric**, or with the [Fabric Capacities - List Usages](https://learn.microsoft.com/rest/api/microsoftfabric/fabric-capacities/list-by-subscription) API.

> [!NOTE]
> A Fabric capacity bills from creation until it is deleted or paused. Destroy the example when you are done.
