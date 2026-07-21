
function Grant-CServiceControlPermission
{
    <#
    .SYNOPSIS
    Grants permission to control a Windows service.

    .DESCRIPTION
    The `Grant-CServiceControlPermission` grants a principal the permission to control a Windows service (i.e. to use
    PowerShell's service cmdlets to query, start, and stop the service). Pass the service name to the `Name` parameter
    and the principal's name to the `PrincipalName` parameter. The user is granted permission to control the service,
    replacing any existing permissions the principal has.

    By default, only Administrators are allowed to control a service. You may notice that when running the
    `Stop-Service`, `Start-Service`, or `Restart-Service` cmdlets as a non-Administrator, you get permissions errors.
    That's because you need to correct permissions.  This function grants just the permissions needed to use
    PowerShell's `Stop-Service`, `Start-Service`, and `Restart-Service` cmdlets to control a service.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-CServicePermission

    .LINK
    Revoke-CServicePermission

    .EXAMPLE
    Grant-CServiceControlPermission -ServiceName 'TPSReport' -PrincipalName 'INITRODE\Builders'

    Grants the INITRODE\Builders group permission to control the TPSReport service.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    param(
        # The name of the service.
        [Parameter(Mandatory)]
        [String] $Name,

        # The user/group name being given access.
        [Parameter(Mandatory)]
        [String] $PrincipalName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Grant-CServicePermission -Name $Name `
                             -PrincipalName $PrincipalName `
                             -Permission 'QueryStatus, EnumerateDependents, Start, Stop'
}
