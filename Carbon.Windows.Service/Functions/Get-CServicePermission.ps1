
function Get-CServicePermission
{
    <#
    .SYNOPSIS
    Gets the permissions for a service.

    .DESCRIPTION
    The `Get-CServicePermission` returns the permissions for a service. Pass the service's name to the `Name` parameter.
    It uses the Windows API's `QueryServiceObjectSecurity` function to get the discretionary ACL for the service. It
    converts each of the ACL's access control entries (ACE) into `[Security.AccessControl.AccessRule]` objects and
    returns them. Any system audit or alarm ACEs are skipped. Return objects will have a `ServiceAccessRights` property
    that is a flags enumeration of the permissions.

    To get the permissions for a specific principal, pass its name to the `PrincipalName` parameter.

    The type of the objects returned and the type of the `ServiceAccessRights` enum are an implementation detail and
    should be ignored.

    To access the service ACEs, use `Get-CServiceAcl`.

    .LINK
    Grant-ServicePermissions

    .LINK
    Revoke-ServicePermissions

    .LINK
    Get-CServiceAcl

    .LINK
    Set-CServiceACl

    .EXAMPLE
    Get-CServicePermission -Name 'Hyperdrive'

    Gets the access rules for the `Hyperdrive` service.

    .EXAMPLE
    Get-CServicePermission -Name 'Hyperdrive' -PrincipalName 'FALCON\HSolo'

    Gets just Han's permissions to control the `Hyperdrive` service.
    #>
    [CmdletBinding()]
    param(
        # The name of the service whose permissions to return.
        [Parameter(Mandatory)]
        [String] $Name,

        # The specific principal whose permissions to get. Wildcards *not* supported.
        [String] $PrincipalName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $dacl = Get-CServiceAcl -Name $Name

    $principal = $null
    if ($PrincipalName)
    {
        $principal = Resolve-CPrincipal -Name $PrincipalName
        if( -not $principal )
        {
            return
        }
    }

    $dacl |
        ForEach-Object {
            $ace = $_

            $identity = $ace.SecurityIdentifier;
            if ($identity.IsValidTargetType([NTAccount]))
            {
                $numErrorsBefore = $Global:Error.Count
                try
                {
                    $identity = $identity.Translate([NTAccount])
                }
                catch [IdentityNotMappedException]
                {
                    # user doesn't exist anymore.  So sad.
                    $numErrorsNow = $Global:Error.Count
                    for ($idx = 0 ; $idx -lt ($numErrorsNow - $numErrorsBefore) ; $idx++)
                    {
                        $Global:Error.RemoveAt(0)
                    }
                }
            }

            if ($ace.AceQualifier -eq [AceQualifier]::AccessAllowed)
            {
                $ruleType = [AccessControlType]::Allow
            }
            elseif ($ace.AceQualifier -eq [AceQualifier]::AccessDenied)
            {
                $ruleType = [AccessControlType]::Deny
            }
            else
            {
                $msg = "Get-CServicePermission: Service ${Name}: skipping unsupported $($ace.AceQualifier) ACE for " +
                       "princial ""${identity}""."
                Write-Verbose $msg
                return
            }

            [Carbon_Windows_Service_ServiceAccessRule_v1]::New($identity, $ace.AccessMask, $ruleType)
        } |
        Where-Object {
            if( $principal )
            {
                return ($_.IdentityReference.Value -eq $principal.FullName)
            }
            return $_
        }
}
