# Overview

The Carbon.Windows.Service PowerShell module helps manage Windows services. It can get all service configuration, test
if services are installed, install services, uninstall services, and manage permissions to services.

# System Requirements

* Windows PowerShell 5.1 and .NET 4.6.1+
* PowerShell Core 6+

# Installing

To install globally:

```powershell
Install-Module -Name 'Carbon.Windows.Service'
Import-Module -Name 'Carbon.Windows.Service'
```

To install privately:

```powershell
Save-Module -Name 'Carbon.Windows.Service' -Path '.'
Import-Module -Name '.\Carbon.Windows.Service'
```

# Commands

| Function | Description |
| -------- | ----------- |
| [`Assert-CService`](Carbon.Windows.Service/Functions/Assert-CService.ps1) | Tests if a service exists, writing an error if it doesn't. |
| [`Get-CServiceAcl`](Carbon.Windows.Service/Functions/Get-CServiceAcl.ps1) | Gets a service ACL, which controls who has permission to view and manage a service. |
| [`Get-CServiceConfiguration`](Carbon.Windows.Service/Functions/Get-CServiceConfiguration.ps1) | Gets all a service's configuration. |
| [`Get-CServicePermission`](Carbon.Windows.Service/Functions/Get-CServicePermission.ps1) | Gets a service's permissions/access rules. |
| [`Get-CServicePreferredNode`](Carbon.Windows.Service/Functions/Get-CServicePreferredNode.ps1) | Gets a service's preferred NUMA node. |
| [`Get-CServiceSecurityDescriptor`](Carbon.Windows.Service/Functions/Get-CServiceSecurityDescriptor.ps1) | Gets a service's raw security descriptor. |
| [`Grant-CServiceControlPermission`](Carbon.Windows.Service/Functions/Grant-CServiceControlPermission.ps1) | Grants a principal the permission to control (start/stop) a service. |
| [`Grant-CServicePermission`](Carbon.Windows.Service/Functions/Grant-CServicePermission.ps1) |  Grants a principal permissions to a service. |
| [`Install-CService`](Carbon.Windows.Service/Functions/Install-CService.ps1) | Installs a service, gracefully handling if a service is or isn't installed. |
| [`Restart-CRemoteService`](Carbon.Windows.Service/Functions/Restart-CRemoteService.ps1) | Restarts a service on a remote computer. |
| [`Revoke-CServicePermission`](Carbon.Windows.Service/Functions/Revoke-CServicePermission.ps1) | Removes a principal's permissions to a service. |
| [`Set-CServiceAcl`](Carbon.Windows.Service/Functions/Set-CServiceAcl.ps1) | Sets a service's ACL. |
| [`Test-CService`](Carbon.Windows.Service/Functions/Test-CService.ps1) | Tests if a servic exist without writing any errors if it doesn't. |
| [`Uninstall-CService`](Carbon.Windows.Service/Functions/Uninstall-CService.ps1) | Uninstalls a service, gracefully handling if the service has already been uninstalled, and properly stopping the service before uninstalling it. |
