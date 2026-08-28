
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.Windows.Service' -Resolve) -Verbose:$false

    function ThenError
    {
        param(
            [Parameter(Mandatory, ParameterSetName='IsEmpty')]
            [switch] $IsEmpty,

            [Parameter(ParameterSetName='MatchesRegex')]
            [int] $At = 0,

            [Parameter(Mandatory, ParameterSetName='MatchesRegex')]
            [String] $MatchesRegex
        )

        if ($IsEmpty)
        {
            $Global:Error | Should -BeNullOrEmpty
        }

        if ($MatchesRegex)
        {
            $Global:Error.Count | Should -BeGreaterOrEqual $At
            $Global:Error[$At] | Should -Match $MatchesRegex
        }
    }
}

Describe 'Get-CServiceConfiguration' {
    BeforeEach {
        $Global:Error.Clear()
    }

    $svcNames =
            Get-Service |
            # Skip Carbon services. They could get uninstalled at any moment.
            Where-Object 'Name' -NotLike 'Carbon*' |
            # Unqueryable on the build servers
            Where-Object 'Name' -NotLike 'CDPUserSvc*' |
            # Description service on my computer fails.
            Where-Object 'Name' -NotIn @('WaaSMedicSvc') |
            # Select-Object -First 5 |
            Select-Object -ExpandProperty 'Name'
    It 'reads <_> service preferred node' -ForEach $svcNames {
        $svc = Get-Service -Name $_
        $preferredNode = $svc | Get-CServicePreferredNode
        ThenError -IsEmpty
        $preferredNode | Should -BeNullOrEmpty

        $preferredNode = Get-CSErvicePreferredNode -Name $svc.Name
        ThenError -IsEmpty
        $preferredNode | Should -BeNullOrEmpty
    }
}
