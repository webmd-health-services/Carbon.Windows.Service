
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon.Windows.Service' -Resolve) -Verbose:$false
}

Describe 'Test-CService' {
    BeforeEach {
        $Global:Error.Clear()
    }

    Context 'service exists' {
        $svcNames =
            Get-Service -ErrorAction Ignore |
            # GoogleUpdaterInternalService causes intermittent problems on the build servers
            Where-Object 'ServiceName' -NotLike 'GoogleUpdater*' |
            Select-Object -ExpandProperty 'ServiceName'
        It 'returns true for <_> service' -ForEach $svcNames {
            Test-CService -Name $_ | Should -BeTrue
            $Global:Error | Should -BeNullOrEmpty
        }
    }

    Context 'service does not exist' {
        It 'returns false' {
            Test-CService -Name 'ISureHopeIDoNotExist' | Should -BeFalse
        }
    }

    Context 'service is device driver' {
        $svcNames = [ServiceProcess.ServiceController]::GetDevices() | Select-Object -ExpandProperty 'ServiceName'

        It 'returns true for <_> driver' -ForEach $svcNames {
            Test-CService -Name $_ | Should -BeTrue
            $Global:Error | Should -BeNullOrEmpty
        }
    }
}