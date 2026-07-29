
function Set-CServiceAcl
{
    <#
    .SYNOPSIS
    Sets a service's discretionary access control list (i.e. DACL).

    .DESCRIPTION
    The existing DACL is replaced with the new DACL.  No previous permissions are preserved.  That's your job.  You're
    warned!

    You probably want `Grant-CServicePermission` or `Revoke-CServicePermission` instead.

    .LINK
    Get-CServicePermission

    .LINK
    Grant-CServicePermission

    .LINK
    Revoke-CServicePermission

    .EXAMPLE
    Set-ServiceDacl -Name 'Hyperdrive' -Dacl $dacl

    Replaces the DACL on the `Hyperdrive` service.  Yikes!  Sounds like something the Empire would do, though.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The service whose DACL to replace.
        [Parameter(Mandatory)]
        [String] $Name,

        # The service's new DACL.
        [Parameter(Mandatory)]
        [DiscretionaryAcl] $Dacl
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $daclBytes = [byte[]]::New($Dacl.BinaryLength)
    $Dacl.GetBinaryForm($daclBytes, 0)
    $rawAcl = [RawAcl]::New($daclBytes, 0)
    $sd = [RawSecurityDescriptor]::New([ControlFlags]::DiscretionaryAclPresent, $null, $null, $null, $rawAcl)

    $scmHandle = Invoke-AdvApiOpenSCManager
    if (-not $scmHandle)
    {
        return
    }

    try
    {
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $scmHandle -ServiceName $Name -DesiredAccess WriteDac
        if (-not $svcHandle)
        {
            return
        }

        try
        {
            if( $PSCmdlet.ShouldProcess( ("{0} service DACL" -f $Name), "set" ) )
            {
                Invoke-AdvApiSetServiceObjectSecurity -ServiceHandle $svcHandle `
                                                      -SecurityInformation DiscretionaryAcl `
                                                      -SecurityDescriptor $sd
            }
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
