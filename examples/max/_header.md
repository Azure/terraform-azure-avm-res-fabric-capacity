# Max example

This deploys the module exercising every AVM interface the `Microsoft.Fabric/capacities` resource supports:

- a **resource lock** (`CanNotDelete`);
- a **control-plane Azure RBAC** role assignment (`Reader`) granted to a user-assigned managed identity;
- **tags**;
- explicit **retry** and **timeouts** configuration.

Diagnostic settings, managed identities, private endpoints and customer-managed keys are intentionally absent — the Fabric capacities resource does not support them. See the [module notes](../../README.md#notes) for the evidence behind each exclusion.

## Registering `Microsoft.Fabric`

`Microsoft.Fabric` is not registered on a subscription by default, and a subscription that has never deployed Fabric rejects the capacity `PUT` with `409 MissingSubscriptionRegistration`. The example registers the provider with an `azapi_resource_action`. That `POST` returns as soon as the request is accepted rather than when the provider reaches `Registered`, so `retry.error_message_regex` also carries `MissingSubscriptionRegistration` and retries until registration completes.

## Why Sweden Central?

The example pins `swedencentral` rather than randomising a region.

Fabric [capacity-unit (CU) quota](https://learn.microsoft.com/fabric/enterprise/fabric-quotas) is granted **per subscription, per region**. A subscription that has never used Fabric shows a limit of `0` CUs in most regions, and `Microsoft.Fabric/capacities` fails to create there until a quota-increase request is approved. Randomising the region — as `Azure/avm-utl-regions` does — makes the example fail intermittently for that reason alone, and Fabric capacities are not offered in every region either.

Sweden Central carries default, out-of-the-box Fabric CU quota, so `terraform apply` succeeds on a fresh subscription with no quota request. Change `local.location` to any region where you hold Fabric quota; check yours in **Azure portal → Quotas → Microsoft Fabric**, or with the [Fabric Capacities - List Usages](https://learn.microsoft.com/rest/api/microsoftfabric/fabric-capacities/list-by-subscription) API.

> [!NOTE]
> A Fabric capacity bills from creation until it is deleted or paused. Destroy the example when you are done.
