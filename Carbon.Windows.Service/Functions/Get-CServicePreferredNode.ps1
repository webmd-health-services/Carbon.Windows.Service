

function Get-CServicePreferredNode
{
    <#
    .SYNOPSIS
    Gets a service's preferred node.

    .DESCRIPTION
    The `Get-CServiceConfiguration` function gets a service's preferred, NUMA node. It uses the Windows API's
    `QueryServiceConfig2` function. Pass the name of the service to the `Name` parameter. If NUMA isn't enabled, returns
    a `[ushort]` representing the service's node.

    If the function writes a "The parameter is incorrect" Win32 error, it is likely because the Windows API is
    reporting that NUMA is enabled when it isn't. You should only call this function if you *know* NUMA is enabled on
    the computer on which this is running.

    .EXAMPLE
    Get-Service | Get-CServicePreferredNode

    Demonstrates how you can pipe in a `ServiceController` object to load the service. This works for services on remote
    computers as well.

    .EXAMPLE
    Get-CServicePreferredNode -Name  'w3svc'

    Demonstrates how you can get a specific service's configuration.

    .EXAMPLE
    Get-CServicePreferredNode -Name 'w3svc' -ComputerName 'enterprise'

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

        $scmHandle = $null

        # We haven't found out of NUMA is enabled on this computer yet.
        if ($null -eq $script:numaEnabled)
        {
            # Per https://learn.microsoft.com/en-us/windows/win32/memory/allocating-memory-from-a-numa-node,
            # GetNumaHighestNodeNumber is the way to determine if NUMA is enabled or not.
            $script:numaEnabled = Invoke-KernelGetNumaHighestNodeNumber
        }

        if (-not $script:numaEnabled)
        {
            return
        }

        $scmHandle = Invoke-AdvApiOpenSCManager -MachineName $ComputerName
    }

    process
    {
        if (-not $script:numaEnabled)
        {
            return
        }

        $svcHandle =
            Invoke-AdvApiOpenService -SCManagerHandle $scmHandle -ServiceName $Name -DesiredAccess 'QueryConfig'
        if (-not $svcHandle)
        {
            return
        }

        try
        {
            return Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel PreferredNode
        }
        finally
        {
            $svcHandle | Invoke-AdvApiCloseServiceHandle
        }
    }

    end
    {
        if ($scmHandle)
        {
            $scmHandle | Invoke-AdvApiCloseServiceHandle
        }
    }
}
