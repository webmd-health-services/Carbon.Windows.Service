

function Get-CServiceConfiguration
{
    <#
    .SYNOPSIS
    Gets a service's full configuration, e.g. username, path, failure actions, etc.

    .DESCRIPTION
    The `Get-CServiceConfiguration` function gets service configuration information. It uses the Windows API's
    `QueryServiceConfig` and `QueryServiceConfig2` functions. Pass the name of the service to the `Name` parameter. That
    service's full configuration is returned. You can also pipe `[ServiceProcess.ServiceController]` objects (e.g., the
    output of the `Get-Service` cmdlet).

    Returned objects have the following properties:

    | Name                            | Description                        | Windows API Structure/Property |
    | ------------------------------- | ---------------------------------- | ------------------------------ |
    | `[string] Name`                 | Name                               |                                |
    | `[Enum] ServiceType`            | Type                               | [`QUERY_SERVICE_CONFIGW.dwServiceType`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[Enum] StartType`              | When to start.                     | [`QUERY_SERVICE_CONFIGW.dwStartType`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[Enum] ErrorControl`           | Startup error handling.            | [`QUERY_SERVICE_CONFIGW.dwErrorControl`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[string] Path`                 | Executable path, with arguments.   | [`QUERY_SERVICE_CONFIGW.lpBinaryPathName`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[string] LoadOrderGroup`       | Load ordering group.               | [`QUERY_SERVICE_CONFIGW.lpLoadOrderGroup`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[uint] TagID`                  | Unique tag.                        | [`QUERY_SERVICE_CONFIGW.dwTagId`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[string[]] Dependencies`       | Names of dependencies.             | [`QUERY_SERVICE_CONFIGW.lpDependencies`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[string] UserName`             | User/Identity/Principal name       | [`QUERY_SERVICE_CONFIGW.lpServiceStartName`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[string] DisplayName`          | Display name                       | [`QUERY_SERVICE_CONFIGW.lpDisplayName`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-query_service_configw) |
    | `[bool] DelayedAutoStart`       | Starts automatically, but delayed? | [`SERVICE_DELAYED_AUTO_START_INFO.fDelayedAutostart`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_delayed_auto_start_info) |
    | `[string] Description`          | Description                        | [`SERVICE_DESCRIPTIONW.lpDescription`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_descriptionw) |
    | `[TimeSpan] FailureResetPeriod` | Failure reset frequency.           | [`SERVICE_FAILURE_ACTIONSW.dwResetPeriod`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actionsw) |
    | `[string] FailureRebootMessage` | Reboot message to send to users.   | [`SERVICE_FAILURE_ACTIONSW.lpRebootMsg`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actionsw) |
    | `[string] FailureCommand`       | Command for "run command" failure actions. | [`SERVICE_FAILURE_ACTIONSW.lpCommand`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actionsw) |
    | `[Object[]] FailureActions`     | Failure actions.                   | [`SC_ACTION`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-sc_action) |
    | `[bool] FailureActionsOnNonCrashFailures` | Shutdown error handling. | [`SERVICE_FAILURE_ACTIONS_FLAG.fFailureActionsOnNonCrashFailures`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actions_flag) |
    | `[ushort] PreferredNode`        | Preferred NUMA node.               | [`SERVICE_PREFERRED_NODE_INFO.usPreferredNode`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_preferred_node_info) |
    | `[TimeSpan] PreshutdownTimeout` | Shutdown timeout.                  | [`SERVICE_PRESHUTDOWN_INFO.dwPreshutdownTimeout`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_preshutdown_info) |
    | `[string[]] RequiredPrivileges` | Required privileges.               | [`pmszRequiredPrivileges`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_required_privileges_infow) |
    | `[Enum] SidType`                | SID type.                          | [`SERVICE_SID_INFO.dwServiceSidType`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_sid_info) |
    | `[Object] Triggers`             | Trigger events.                    | [`SERVICE_TRIGGER`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger) |
    | `[Enum] ProtectionType`         | Protection type.                   | [`SERVICE_LAUNCH_PROTECTED_INFO.dwLaunchProtected`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_launch_protected_info) |

    Each failure action has the following properties:

    | Name               | Description                 | Windows API Structure/Property |
    | ------------------ | --------------------------- | ------------------------------ |
    | `[Enum] Type`      | Type                        | [`SC_ACTION.Type`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-sc_action) |
    | `[TimeSpan] Delay` | Delay before taking action. | [`SC_ACTION.Delay`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-sc_action) |

    Each trigger has the following properties:

    | Name                   | Description | Windows API Structure/Property |
    | ---------------------- | ----------- | ------------------------------ |
    | `[Enum] Type`          | Type        | [`SERVICE_TRIGGER.dwTriggerType`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger) |
    | `[Enum] Action`        | Action      | [`SERVICE_TRIGGER.dwAction`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger) |
    | `[Guid] Subtype`       | Subtype     | [`SERVICE_TRIGGER.pTriggerSubtype`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger) |
    | `[Object[]] DataItems` | Trigger-specific data. | [`SERVICE_TRIGGER_SPECIFIC_DATA_ITEM`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger_specific_data_item) |

    Each trigger data item has the following properties:

    | Name            | Description            | Windows API Structure/Property |
    | --------------- | ---------------------- | ------------------------------ |
    | `[Enum] Type`   | Type                   | [`SERVICE_TRIGGER_SPECIFIC_DATA_ITEM.dwDataType`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger_specific_data_item)
    | `[Object] Data` | Trigger-specific data. | [`SERVICE_TRIGGER_SPECIFIC_DATA_ITEM.pData`](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger_specific_data_item)

    Ignore types for enums and objects. Those are implementation details and are subject to change at any time. Enum
    names/values shouldn't change.

    The user running this function must have `QueryConfig` permissions to the service. Use `Grant-CServicePermission` to
    grant service permissions.

    .LINK
    Grant-CServicePermission

    .EXAMPLE
    Get-Service | Get-CServiceConfiguration

    Demonstrates how you can pipe in a `ServiceController` object to load the service. This works for services on remote
    computers as well.

    .EXAMPLE
    Get-CServiceConfiguration -Name  'w3svc'

    Demonstrates how you can get a specific service's configuration.

    .EXAMPLE
    Get-CServiceConfiguration -Name 'w3svc' -ComputerName 'enterprise'

    Demonstrates how to get service configuration for a service on a remote computer.
    #>
    [CmdletBinding()]
    param(
        # The name of the service. Wildcards are *not* supported. You can pipe `[ServiceProcess.ServiceController]`
        # objects as well.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
        [String] $Name,

        # The name of the computer where the service lives.
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('MachineName')]
        [String] $ComputerName
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $scmHandle = Invoke-AdvApiOpenSCManager -MachineName $ComputerName
    }

    process
    {
        $svcHandle =
            Invoke-AdvApiOpenService -SCManagerHandle $scmHandle -ServiceName $Name -DesiredAccess 'QueryConfig'
        if (-not $svcHandle)
        {
            return
        }

        $config = [ordered]@{}
        try
        {
            $config['Name'] = $Name

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig -ServiceHandle $svcHandle
            if ($winSvcCfg)
            {
                $config['ServiceType'] = $winSvcCfg.ServiceType
                $config['StartType'] = $winSvcCfg.StartType
                $config['ErrorControl'] = $winSvcCfg.ErrorControl
                $config['Path'] = $winSvcCfg.BinaryPathName
                $config['LoadOrderGroup'] = $winSvcCfg.LoadOrderGroup
                $config['TagID'] = $winSvcCfg.TagID
                $config['Dependencies'] = $winSvcCfg.Dependencies
                $config['UserName'] = $winSvcCfg.ServiceStartName.Trim('"')
                $config['DisplayName'] = $winSvcCfg.DisplayName
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel DelayedAutoStart
            if ($winSvcCfg)
            {
                $config['DelayedAutoStart'] = $winSvcCfg.DelayedAutoStart
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Description
            if ($winSvcCfg)
            {
                $config['Description'] = $winSvcCfg.Description
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel FailureActions
            if ($winSvcCfg)
            {
                $config['FailureResetPeriod'] = $null
                # 0xffffffff means INFINITE or not set
                if ($winSvcCfg.ResetPeriod -ne [UInt32]0xffffffffl)
                {
                    $config['FailureResetPeriod'] = [TimeSpan]::New(0, 0, $winSvcCfg.ResetPeriod)
                }
                $config['FailureRebootMessage'] = $winSvcCfg.RebootMessage
                $config['FailureCommand'] = $winSvcCfg.Command
                [Object[]] $failureActions =
                    $winSvcCfg.Actions |
                    ForEach-Object {
                        return [pscustomobject]@{
                            Type = $_.Type
                            Delay = [TimeSpan]::New(0, 0, 0, 0, $_.Delay)
                        }
                    }
                if ($null -eq $failureActions)
                {
                    $failureActions = [Object[]]::New(0)
                }
                $config['FailureActions'] = $failureActions
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel FailureActionsFlag
            if ($winSvcCfg)
            {
                $config['FailureActionsOnNonCrashFailures'] = $winSvcCfg.FailureActionsOnNonCrashFailures
            }

            $config['PreferredNode'] = $null
            if ($null -eq $script:numaEnabled -or $script:numaEnabled)
            {
                # If NUMA isn't enabled, querying PreferredNode results in a "The parameter is incorrect." (87) error.
                # This is the only way I've found to reliably detect if NUMA is enabled.
                $preferredNodeErrors = @()
                $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle `
                                                              -InfoLevel PreferredNode `
                                                              -ErrorAction SilentlyContinue `
                                                              -ErrorVariable 'preferredNodeErrors'
                if ($winSvcCfg)
                {
                    $script:numaEnabled = $true
                    $config['PreferredNode'] = $winSvcCfg.PreferredNode
                }
                else
                {
                    $parameterIncorrect = 87
                    $paramIncorrectEx =
                        $preferredNodeErrors |
                        Select-Object -ExpandProperty 'Exception' -ErrorAction Ignore |
                        Where-Object 'NativeErrorCode' -EQ $parameterIncorrect -ErrorAction Ignore
                    if ($paramIncorrectEx)
                    {
                        $script:numaEnabled = $false
                        for ($idx = 0 ; $idx -lt $preferredNodeErrors.Count ; $idx++)
                        {
                            $Global:Error.RemoveAt(0)
                        }
                    }
                }
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Preshutdown
            if ($winSvcCfg)
            {
                $config['PreshutdownTimeout'] = [TimeSpan]::New(0, 0, 0, 0, $winSvcCfg.PreshutdownTimeout)
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel RequiredPrivileges
            if ($winSvcCfg)
            {
                if ($winSvcCfg.RequiredPrivileges)
                {
                    $config['RequiredPrivileges'] = $winSvcCfg.RequiredPrivileges
                }
                else
                {
                    $config['RequiredPrivileges'] = [String[]]::New(0)
                }
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel SidType
            if ($winSvcCfg)
            {
                $config['SidType'] = $winSvcCfg.SidType
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Triggers
            if ($winSvcCfg)
            {
                $config['Triggers'] = $winSvcCfg.Triggers
            }

            $winSvcCfg = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel LaunchProtected
            if ($winSvcCfg)
            {
                $config['LaunchProtected'] = $winSvcCfg.LaunchProtected
            }

            return [pscustomobject]$config
        }
        finally
        {
            $svcHandle | Invoke-AdvApiCloseServiceHandle
        }
    }

    end
    {
        $scmHandle | Invoke-AdvApiCloseServiceHandle
    }
}
