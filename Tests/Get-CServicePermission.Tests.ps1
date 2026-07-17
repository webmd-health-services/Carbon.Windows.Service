
using module ..\Carbon.Windows.Service
using namespace System.Security.AccessControl

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeDiscovery {
    Set-StrictMode -Version 'Latest'

    $cWinSvcDirPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.Windows.Service' -Resolve
    Import-Module -Name $cWinSvcDirPath -Verbose:$false
    Import-Module -Name (Join-Path -Path $cWinSvcDirPath -ChildPath 'M\Carbon.Accounts' -Resolve) `
                  -Function @('Test-CRunAsElevated') `
                  -Prefix 'T' `
                  -Verbose:$false
}

BeforeAll {
    Set-StrictMode -Version 'Latest'

    function ThenError
    {
        param(
            [Parameter(Mandatory)]
            [switch] $IsEmpty
        )

        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'Get-CServicePermission' {
    BeforeEach {
        $Global:Error.Clear()
    }

    # Services that require elevated permissions to query security descriptor.
    $elevatedSvcNames = @('LSM', 'NetSetupSvc', 'ose64', 'pla', 'QWAVE')
    if ((Test-TCRunAsElevated))
    {
        $elevatedSvcNames = @()
    }
    $svcNames =
            Get-Service -ErrorAction Ignore |
            Where-Object 'Name' -NotIn $elevatedSvcNames |
            # Select-Object -First 5 |
            Select-Object -ExpandProperty 'Name'
    It 'reads <_> service permissions' -ForEach $svcNames {
        $perms = Get-CServicePermission -Name $_
        ThenError -IsEmpty
        $perms | Should -Not -BeNullOrEmpty
        foreach ($perm in $perms)
        {
            $perm.GetType().FullName | Should -Be 'Carbon_Windows_Service_ServiceAccessRule_v1'
            $perm.IdentityReference | Should -Not -BeNullOrEmpty
            $perm.ServiceAccessRights | Should -Not -BeNullOrEmpty
            $perm.ServiceAccessRights.GetType().FullName | Should -Be 'Carbon_Windows_Service_ServiceAccessRights'
            $perm.AccessControlType | Should -Not -BeNullOrEmpty
            $perm.InheritanceFlags | Should -Be ([InheritanceFlags]::None)
            $perm.PropagationFlags | Should -Be ([PropagationFlags]::None)
        }
    }
}
