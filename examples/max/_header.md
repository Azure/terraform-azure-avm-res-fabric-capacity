# Max example

This deploys the module exercising every AVM interface the `Microsoft.Fabric/capacities` resource supports:

- a **resource lock** (`CanNotDelete`);
- a **control-plane Azure RBAC** role assignment (`Reader`) granted to a user-assigned managed identity;
- **tags**;
- explicit **retry** and **timeouts** configuration.

Diagnostic settings, managed identities, private endpoints and customer-managed keys are intentionally absent — the Fabric capacities resource does not support them. See the [module notes](../../README.md#notes) for the evidence behind each exclusion.

> [!NOTE]
> A Fabric capacity bills from creation until it is deleted or paused. Destroy the example when you are done.
