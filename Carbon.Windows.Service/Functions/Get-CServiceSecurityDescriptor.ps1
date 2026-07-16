
function Get-CServiceSecurityDescriptor
{
    <#
    .SYNOPSIS
    Gets a Windows service's security descriptor.

    .DESCRIPTION
    The `Get-CServiceSecurityDescriptor` function gets a Windows service's security descriptor. Pass the service's name
    to the `Name` parameter (wildcards *not* accepted). The function uses the Windows API's `OpenSCManager`,
    `OpenService`, and `QueryServiceObjectSecurity` functions to get the service's security descriptor. Returns a
    `[Security.AccessControl.RawSecurityDescriptor]` object with `Owner`, `Group`, and `DiscretionaryAcl` set. The
    `SystemAcl` is not set.

    User must have `ReadControl` permission to a service. Even with that permission, some services still require
    elevated access.

    .OUTPUTS
    System.Security.AccessControl.RawSecurityDescriptor.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-ServicePermissions

    .LINK
    Revoke-ServicePermissions

    .EXAMPLE
    Get-CServiceSecurityDescriptor -Name 'Hyperdrive'

    Gets the hyperdrive service's raw security descriptor.
    #>
    [CmdletBinding()]
    [OutputType([Security.AccessControl.RawSecurityDescriptor])]
    param(
        # The name of the service whose security descriptor to return. Wildcards *not* accepted.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $scmHandle = Invoke-AdvApiOpenSCManager -DesiredAccess Read
    if (-not $scmHandle)
    {
        return
    }

    try
    {
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $scmHandle -ServiceName $Name -DesiredAccess ReadControl
        if (-not $svcHandle)
        {
            return
        }

        try
        {
            Invoke-AdvApiQueryServiceObjectSecurity -ServiceHandle $svcHandle `
                                                    -SecurityInformation 'Owner, Group, DiscretionaryAcl'
        }
        finally
        {
            $svcHandle | Invoke-AdvApiCloseServiceHandle
        }
    }
    finally
    {
        $scmHandle | Invoke-AdvApiCloseServiceHandle
    }
}

