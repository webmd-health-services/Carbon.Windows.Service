
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

Describe 'Get-CServiceSecurityDescriptor' {
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
    It 'reads <_> service security descriptor' -ForEach $svcNames {
        $sd = Get-CServiceSecurityDescriptor -Name $_
        ThenError -IsEmpty
        $sd | Should -Not -BeNullOrEmpty
        $sd.Owner | Should -Not -BeNullOrEmpty
        $sd.Group | Should -Not -BeNullOrEmpty
        $sd.DiscretionaryAcl | Should -Not -BeNullOrEmpty
    }
}
