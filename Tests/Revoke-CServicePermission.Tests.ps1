
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
        $script:groupName = 'CRevokeSvcPerm'
        Install-TCLocalGroup -Name $script:groupName -Description 'Carbon Revoke-CServicePermission'
    }

    $script:serviceName = 'CarbonRevokeServicePermission'
    $servicePath = Join-Path -Path $PSScriptRoot -ChildPath 'NoOpService.exe' -Resolve
    Install-CService -Name $serviceName -Path $servicePath -StartupType Disabled

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
    Uninstall-CService -Name $script:serviceName
}

Describe 'Revoke-CServicePermission' {
    BeforeEach {
        Grant-CServicePermission -Name $script:serviceName -PrincipalName $script:groupName -Permission QueryConfig
        $Global:Error.Clear()
    }

    It 'revokes permission' {
        Revoke-CServicePermission -Name $script:serviceName -PrincipalName $script:groupName
        ThenPermission -IsNull
    }

    It 'supports whatif' {
        Revoke-CServicePermission -Name $script:serviceName -PrincipalName $script:groupName -WhatIf
        ThenPermission -Is QueryConfig
    }

    It 'is idempotent' {
        Revoke-CServicePermission -Name $script:serviceName -PrincipalName $script:groupName
        Mock -CommandName 'Set-CServiceAcl' -ModuleName 'Carbon.Windows.Service'
        Revoke-CServicePermission -Name $script:serviceName -PrincipalName $script:groupName
        Should -Not -Invoke 'Set-CServiceAcl' -ModuleName 'Carbon.Windows.Service'
    }
}
