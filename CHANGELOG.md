
# Carbon.Windows.Service Changelog

## 1.0.0

### Upgrade Instructions

If switching from Carbon,

* remove usages of these properties on `[System.ServiceProcess.ServiceController]` objects (e.g., objects returned by
  `Get-Service`). Instead, use `Get-CServiceConfiguration` to get service configuration.
    * `DelayedAutoStart`
    * `Description`
    * `ErrorControl`
    * `FailureProgram`
    * `FirstFailure`
    * `LoadOrderGroup`
    * `Path`
    * `RebootDelay`
    * `RebootDelayMinutes`
    * `RebootMessage`
    * `ResetPeriod`
    * `ResetPeriodDays`
    * `RestartDelay`
    * `RestartDelayMinutes`
    * `RunCommandDelay`
    * `RunCommandDelayMinutes`
    * `SecondFailure`
    * `StartMode`
    * `StartType`
    * `TagID`
    * `ThirdFailure`
    * `UserName`
* update usages of objects returned by `Get-CServiceConfiguration`:
    * test usages. The object returned is now a generic object.
    * remove usages of `FirstFailure`, `SecondFailure`, and `ThirdFailure` properties and use the new `FailureActions`
      array instead, which is an array of failure actions.
    * remove usages of the `RunCommandDelay`, `RunCommandDelayMinutes`, `RebootDelay`, `RebootDelayMinutes`,
      `RestartDelay`, and `RestartDelayMinutes` and replace with the `Type` and `Delay` properties of each action in
      `FailureActions`. `Get-CServiceConfiguration` was improperly returning these as service-level configuration.
    * check usages of the `ErrorControl` enum property. Its type has changed, but it still has the same underlying
      names and values.

### Added

* PowerShell (pwsh.exe) support.
* `Get-CServiceConfiguration` now returns all configuration available via the Windows API's
  [`QueryServiceConfig`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/nf-winsvc-queryserviceconfigw) and
  [`QueryServiceConfig2`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/nf-winsvc-queryserviceconfig2w)
  functions. These properties are new:
    * [`ServiceType`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw)
    * `Dependencies`
    * `DisplayName`
    * [`FailureActions`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-sc_action), an array of
      each of a service's failure actions
    * [`FailureActionsOnNonCrashFailures`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actions_flag)
    * [`PreferredNode`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_preferred_node_info),
      but only if NUMA is enabled.
    * [`PreshutdownTimeout`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_preshutdown_info)
    * [`RequiredPrivileges`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_required_privileges_infow)
    * [`SidType`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_sid_info)
    * [`Triggers`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger)
    * [`LaunchProtected`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_launch_protected_info)
* `Get-CServiceSecurityDescriptor` sets `Owner` and `Group` on the returned security descriptor object.

### Changed

The following changed from Carbon:

* `Get-CServiceConfiguration` returns a generic object.
* The `ErrorControl` enum property on objects returned by `Get-CServiceConfiguration` has a different type, but still
  has the same underlying names and values.
* `Get-CServiceConfiguration` now attempts to get service configuration on remote computer when running in pwsh instead
  of refusing to even try.

### Removed

* The following properties on `[System.ServicePRocess.ServiceController]` objects (e.g. objects returned from
  `Get-Service`):
    * `DelayedAutoStart`
    * `Description`
    * `ErrorControl`
    * `FailureProgram`
    * `FirstFailure`
    * `LoadOrderGroup`
    * `Path`
    * `RebootDelay`
    * `RebootDelayMinutes`
    * `RebootMessage`
    * `ResetPeriod`
    * `ResetPeriodDays`
    * `RestartDelay`
    * `RestartDelayMinutes`
    * `RunCommandDelay`
    * `RunCommandDelayMinutes`
    * `SecondFailure`
    * `StartMode`
    * `StartType`
    * `TagID`
    * `ThirdFailure`
    * `UserName`
* The failure action properties on objects returned by `Get-CServiceConfiguration`. Instead, use the new
  `FailureActions` array of action objects.
    * `FirstFailure`
    * `SecondFailure`
    * `ThirdFailure`
    * `RunCommandDelay`
    * `RunCommandDelayMinutes`
    * `RebootDelay`
    * `RebootDelayMinutes`
    * `RestartDelay`
    * `RestartDelayMinutes`
