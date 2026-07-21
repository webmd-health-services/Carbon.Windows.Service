
using namespace System.ServiceProcess

#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.Windows.Service' -Resolve) -Verbose:$false

    $script:serviceName = 'CarbonSetCServiceAcl'
}

Describe 'Set-CServiceAcl' {
    BeforeEach {
        $servicePath = Join-Path -Path $PSScriptRoot -ChildPath 'NoOpService.exe' -Resolve
        Install-CService -Name $serviceName -Path $servicePath -StartupType Disabled
    }

    AfterEach {
        Uninstall-CService -Name $script:serviceName
    }

    It 'changes DACL' {
        $originalSd = Get-CServiceSecurityDescriptor -Name $script:serviceName
        $originalSd | Should -Not -BeNullOrEmpty

        Grant-CServicePermission -Name $script:serviceName -PrincipalName 'Everyone' -Permission QueryConfig
        $newSd = Get-CServiceSecurityDescriptor -Name $script:serviceName
        $newSd | Should -Not -BeNullOrEmpty

        $newSd.GetSddlForm('All') | Should -Not -Be $originalSd.GetSddlForm('All')
    }

    It 'supports WhatIf' {
        $originalSd = Get-CServiceSecurityDescriptor -Name $script:serviceName
        $originalSd | Should -Not -BeNullOrEmpty

        Grant-CServicePermission -Name $script:serviceName -PrincipalName 'Everyone' -Permission QueryConfig -WhatIf
        $newSd = Get-CServiceSecurityDescriptor -Name $script:serviceName
        $newSd | Should -Not -BeNullOrEmpty

        $newSd.GetSddlForm('All') | Should -Be $originalSd.GetSddlForm('All')
    }
}

