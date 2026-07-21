
function Grant-CServicePermission
{
    <#
    .SYNOPSIS
    Grants permissions to a service.

    .DESCRIPTION
    The `Grant-CServicePermission` function grants permissions to a service. Pass the service's name to the `Name`
    parameter, the principal's name to the `PrincipalName` parameter, and the permissions to grant to the `Permission`
    parameter. Valid permissions are:

    * QueryConfig
    * ChangeConfig
    * QueryStatus
    * EnumerateDependents
    * Start
    * Stop
    * PauseContinue
    * Interrogate
    * UserDefinedControl
    * Delete
    * ReadControl
    * WriteDac
    * WriteOwner
    * FullControl

    To grant multiple permissions, use a flags enum string, e.g. `'QueryConfig, QueryStatus, EnumerateDependents'`.

    By default, only Administators are allowed to manage a service.  Use this function to grant other principals
    permissions to manage a service.

    If you just want to grant a user the ability to start/stop/restart a service using PowerShell's `Start-Service`,
    `Stop-Service`, or `Restart-Service` cmdlets, use the `Grant-ServiceControlPermission` function instead.

    Any previous permissions are replaced.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-ServiceControlPermission

    .EXAMPLE
    Grant-CServicePermission -Identity FALCON\Chewbacca -Name Hyperdrive 'QueryStatus, EnumerateDependents, Start, Stop'

    Grants Chewbacca the permissions to query, enumerate dependents, start, and stop the `Hyperdrive` service.
    Coincedentally, these are the permissions that Chewbacca nees to run `Start-Service`, `Stop-Service`,
    `Restart-Service`, and `Get-Service` cmdlets against the `Hyperdrive` service.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    param(
        # The name of the service to grant permissions to.
        [Parameter(Mandatory)]
        [String] $Name,

        # The principal to grant permissions to.
        [Parameter(Mandatory)]
        [String] $PrincipalName,

        # The permissions to grant. Valid values are:
        #
        # * QueryConfig
        # * ChangeConfig
        # * QueryStatus
        # * EnumerateDependents
        # * Start
        # * Stop
        # * PauseContinue
        # * Interrogate
        # * UserDefinedControl
        # * Delete
        # * ReadControl
        # * WriteDac
        # * WriteOwner
        # * FullControl
        #
        # To grant multiple permissions, use a flags enum string, e.g. `'QueryConfig, QueryStatus, EnumerateDependents'`.
        [Parameter(Mandatory)]
        [Carbon_Windows_Service_ServiceAccessRights] $Permission
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

    $perm = Get-CServicePermission -Name $Name -PrincipalName $PrincipalName
    if ($perm -and $perm.ServiceAccessRights -eq $Permission)
    {
        $msg = "[Grant-CServicePermission] ""$($account.FullName)"" already has ""${Permission}"" permission to " +
               """${Name} service."
        Write-Verbose $msg
        return
    }

    $msg = "[Grant-CServicePermission] Granting ""$($account.FullName)"" ""${Permission}"" permission to the " +
           """${Name}"" service."
    Write-Information $msg

    $dacl = Get-CServiceAcl -Name $Name
    $dacl.SetAccess( [Security.AccessControl.AccessControlType]::Allow, $account.Sid, $Permission, 'None', 'None' )
    Set-CServiceAcl -Name $Name -DACL $dacl
}


