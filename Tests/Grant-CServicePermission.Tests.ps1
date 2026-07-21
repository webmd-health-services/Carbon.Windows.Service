
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
        $script:groupName = 'CarbonGrntSvcP'
        Install-TCLocalGroup -Name $script:groupName -Description 'Carbon Grant-CServicePermission'
    }

    function ThenPermission
    {
        param(
            [Parameter(Mandatory, ParameterSetName='Is')]
            [AllowNull()]
            [Carbon_Windows_Service_ServiceAccessRights] $Is,

            [Parameter(Mandatory, ParameterSetName='IsNull')]
            [switch] $IsNull
        )

        $perm = Get-CServicePermission -Name $serviceName -PrincipalName $script:groupName

        if ($Is)
        {
            $perm | Should -Not -BeNullOrEmpty
            $perm.ServiceAccessRights | Should -Be $Is
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

Describe 'Grant-CServicePermission' {
    BeforeEach {
        $serviceName = 'CarbonGrantServicePermission'
        $servicePath = Join-Path -Path $PSScriptRoot -ChildPath 'NoOpService.exe' -Resolve
        Install-CService -Name $serviceName -Path $servicePath -StartupType Disabled

        Revoke-CServicePermission -Name $serviceName -PrincipalName $groupName
        $perms = Get-CServicePermission -Name $serviceName -PrincipalName $groupName
        $perms | Should -BeNullOrEmpty
    }

    $perms = [Enum]::GetValues( [Carbon_Windows_Service_ServiceAccessRights] )
    It 'should grant <_> permission' -ForEach $perms {
        Grant-CServicePermission -Name $serviceName -PrincipalName $script:groupName -Permission $_
        ThenPermission -Is $_
    }

    It 'replaces permissions' {
        Grant-CServicePermission -Name $serviceName -PrincipalName $script:groupName -Permission EnumerateDependents
        ThenPermission -Is EnumerateDependents
        Grant-CServicePermission -Name $serviceName -PrincipalName $script:groupName -Permission QueryConfig
        ThenPermission -Is QueryConfig
    }

    It 'is idempotent' {
        Grant-CServicePermission -Name $serviceName -PrincipalName $script:groupName -Permission QueryConfig
        ThenPermission -Is QueryConfig
        Mock -CommandName 'Set-CServiceAcl' -ModuleName 'Carbon.Windows.Service'
        Grant-CServicePermission -Name $serviceName -PrincipalName $script:groupName -Permission QueryConfig
        Should -Not -Invoke 'Set-CServiceAcl' -ModuleName 'Carbon.Windows.Service'
    }

    It 'supports flags enum string' {
        Grant-CServicePermission -Name $serviceName `
                                 -PrincipalName $script:groupName `
                                 -Permission 'QueryConfig, EnumerateDependents'
        ThenPermission -Is 'QueryConfig, EnumerateDependents'
    }

    It 'supports WhatIf' {
        Grant-CServicePermission -Name $serviceName -PrincipalName $script:groupName -Permission QueryConfig -WhatIf
        ThenPermission -IsNull
    }
}
