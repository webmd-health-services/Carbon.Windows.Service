
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
    It 'reads <_> service configuration' -ForEach $svcNames {
        $svc = Get-Service -Name $_
        $config = $svc | Get-CServiceConfiguration
        ThenError -IsEmpty

        $config | Should -Not -BeNullOrEmpty
        $config.Name | Should -Be $svc.Name
        $config.DisplayName | Should -Be $svc.DisplayName
        $config.ServiceType | Should -BeOfType ([Enum])
        $config.StartType | Should -Be $svc.StartType
        $config.ErrorControl | Should -BeOfType ([Enum])

        $config.TagID | Should -Not -BeNullOrEmpty
        # Get-Service doesn't report one of the RemoteAccess service's dependencies.
        if ($config.Name -ne 'RemoteAccess')
        {
            $config.Dependencies |
                Sort-Object |
                Should -Be ($svc.ServicesDependedOn | Select-Object -ExpandProperty 'Name' | Sort-Object)
        }

        $config.UserName | Should -BeOfType ([String])
        $config.DelayedAutoStart | Should -BeOfType ([bool])
        if ($null -ne $config.Description)
        {
            $config.Description | Should -BeOfType ([String])
        }
        $config.LoadOrderGroup | Should -BeOfType ([String])
        if ($null -ne $config.FailureResetPeriod)
        {
            $config.FailureResetPeriod | Should -BeOfType ([TimeSpan])
        }
        if ($null -ne $config.FailureCommand)
        {
            $config.FailureCommand | Should -BeOfType ([String])
        }
        if ($null -ne $config.FailureRebootMessage)
        {
            $config.FailureRebootMessage | Should -BeOfType ([String])
        }
        ,$config.FailureActions | Should -BeOfType ([Object[]])
        $null -eq $config.FailureActions | Should -BeFalse
        foreach ($action in $config.FailureActions)
        {
            $action | Should -Not -BeNullOrEmpty
            $action.Type | Should -BeOfType ([Enum])
            $action.Delay | Should -BeOfType ([TimeSpan])
        }
        $config.FailureActionsOnNonCrashFailures | Should -BeOfType ([bool])
        if ($null -ne $config.PreferredNode)
        {
            $config.PreferredNode | Should -BeOfType ([Int16])
        }
        $config.PreshutdownTimeout | Should -BeOfType ([TimeSpan])
        ,$config.RequiredPrivileges | Should -BeOfType ([String[]])
        $config.SidType | Should -BeOfType ([Enum])
        ,$config.Triggers | Should -BeOfType ([Object[]])
        $null -eq $config.Triggers | Should -BeFalse
        foreach ($trigger in $config.Triggers)
        {
            $trigger | Should -Not -BeNullOrEmpty
            $trigger.Type | Should -BeOfType ([Enum])
            $trigger.Action | Should -BeOfType ([Enum])
            ,$trigger.DataItems | Should -BeOfType ([Object[]])

            foreach ($datum in $trigger.DataItems)
            {
                $datum | Should -Not -BeNullOrEmpty
                $datum.Type | Should -BeOfType ([Enum])
                $datum.Data | Should -Not -BeNullOrEmpty
                ,$datum.Data | Should -BeOfType ([Object])
            }
        }
        $config.LaunchProtected | Should -BeOfType ([Enum])
    }

    It 'should write an error if the service doesn''t exist' {
        $info = Get-CServiceConfiguration -Name 'YOLOyolo' -ErrorAction SilentlyContinue
        $info | Should -BeNullOrEmpty
        ThenError -MatchesRegex 'does not exist as an installed service'
    }

    It 'should ignore missing service' {
        $info = Get-CServiceConfiguration -Name 'FUBARsnafu' -ErrorAction Ignore
        $info | Should -BeNullOrEmpty
        ThenError -IsEmpty
    }
}
