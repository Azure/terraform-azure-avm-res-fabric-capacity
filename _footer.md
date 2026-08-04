## Notes

### Unsupported AVM extension resources (RMFR4)

[AVM resource-module spec RMFR4](https://azure.github.io/Azure-Verified-Modules/spec/RMFR4) requires resource modules to support `diagnostic_settings`, `role_assignments`, `lock`, `tags`, `managed_identities`, `private_endpoints`, and `customer_managed_key`, where the underlying Azure resource supports them. This module implements `role_assignments`, `lock`, and `tags`. It intentionally does **not** implement `diagnostic_settings`, `managed_identities`, `private_endpoints`, or `customer_managed_key`, because `Microsoft.Fabric/capacities` does not support them:

- **Managed identities** — the `Microsoft.Fabric/capacities` ARM schema (checked against both the `2023-11-01` GA and `2025-01-15-preview` API versions) has no `identity` block. There is no system-assigned or user-assigned identity to attach.
- **Private endpoints** — the resource schema exposes no `privateEndpointConnections` or `publicNetworkAccess` property, and Fabric's private-link surface (`Microsoft.Fabric/privateLinkServicesForFabric`) is a workspace-level concept, not a capacity-level one. A capacity cannot itself be the target of a private endpoint.
- **Customer-managed keys** — the resource schema has no encryption/CMK-related properties.
- **Diagnostic settings** — Azure Monitor does not publish supported metric or log categories for `Microsoft.Fabric/capacities`, so there is no `Microsoft.Insights/diagnosticSettings` target to wire up.

The published Microsoft-owned Bicep AVM module for the same resource type ([`avm/res/fabric/capacity`](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/fabric/capacity)) corroborates this: it implements only `name`, `location`, `tags`, `sku`, `administration.members`, `lock`, and telemetry — no identity, private endpoint, CMK, or diagnostic-settings support either.

If a future Fabric capacities API version adds any of these capabilities, this module should be updated to add the corresponding interface at that time.

### Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.