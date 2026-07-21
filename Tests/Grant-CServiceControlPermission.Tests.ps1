
using module ..\Carbon.Windows.Service

#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    $cwsDirPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.Windows.Service' -Resolve
    Import-Module -Name $cwsDirPath -Verbose:$false
    Import-Module -Name (Join-Path -Path $cwsDirPath -ChildPath 'M\Carbon.Accounts' -Resolve) `
                  -Function @('Install-CLocalGroup', 'Uninstall-CLocalGroup') `
                  -Prefix 'T' `
                  -Verbose:$false

    $script:groupName = 'Everyone'
    if ((Get-Command -Name 'Get-LocalGroup' -CommandType Cmdlet -ErrorAction Ignore))
    {
        $script:groupName = 'CGrantSvcCtrlPerm'
        Install-TCLocalGroup -Name $script:groupName -Description 'Carbon Grant-CServiceControlPermission'
    }

    function ThenPermission
    {
        param(
            [Parameter(Mandatory, ParameterSetName='Is')]
            [AllowNull()]
            [switch] $IsControl,

            [Parameter(Mandatory, ParameterSetName='IsNull')]
            [switch] $IsNull
        )

        $perm = Get-CServicePermission -Name $serviceName -PrincipalName $script:groupName

        if ($IsControl)
        {
            $perm | Should -Not -BeNullOrEmpty
            $perm.ServiceAccessRights | Should -Be 'QueryStatus, EnumerateDependents, Start, Stop'
        }
        else
        {
            $perm | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    if ($script:groupName -ne 'Everyone')
    {
        Uninstall-TCLocalGroup -Name $script:groupName
    }
}

Describe 'Grant-CServiceControlPermission' {
    BeforeEach {
        $serviceName = 'CarbonGrantServiceControlPermission'
        $servicePath = Join-Path -Path $PSScriptRoot -ChildPath 'NoOpService.exe' -Resolve
        Install-CService -Name $serviceName -Path $servicePath -StartupType Disabled

        Revoke-CServicePermission -Name $serviceName -PrincipalName $groupName
        $perms = Get-CServicePermission -Name $serviceName -PrincipalName $groupName
        $perms | Should -BeNullOrEmpty
    }

    It 'should grant control permission' {
        Grant-CServiceControlPermission -Name $serviceName -PrincipalName $script:groupName
        ThenPermission -IsControl
    }

    It 'supports WhatIf' {
        Grant-CServiceControlPermission -Name $serviceName -PrincipalName $script:groupName -WhatIf
        ThenPermission -IsNull
    }
}
