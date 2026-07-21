
function Revoke-CServicePermission
{
    <#
    .SYNOPSIS
    Removes permissions to a service.

    .DESCRIPTION
    The `Revoke-CServicePermission` function removes a principal's permissions to a Windows service. Pass the service's
    name to the `Name` parameter, and the principal's name whose permissions to remove to the `PrincipalName` parameter.
    If the user has permissions, they are removed. If the user has no permissions, nothing happens.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-CServicePermission

    .EXAMPLE
    Revoke-CServicePermission -Name 'Hyperdrive` -PrincipalName 'CLOUDCITY\LCalrissian'

    Removes all of Lando's permissions to control the `Hyperdrive` service.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    param(
        # The service.
        [Parameter(Mandatory)]
        [String] $Name,

        # The principal whose permissions to remove.
        [Parameter(Mandatory)]
        [String] $PrincipalName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = Resolve-CPrincipal -Name $PrincipalName
    if( -not $account )
    {
        return
    }

    if( -not (Assert-CService -Name $Name) )
    {
        return
    }

    if( (Get-CServicePermission -Name $Name -PrincipalName $account.FullName) )
    {
        $msg = "[Revoke-CServicePermission] Removing ""$($account.FullName)"" principal's permissions to the " +
               """${Name}"" service."
        Write-Information $msg

        $dacl = Get-CServiceAcl -Name $Name
        $dacl.Purge( $account.Sid )
        Set-CServiceAcl -Name $Name -Dacl $dacl
    }
 }

