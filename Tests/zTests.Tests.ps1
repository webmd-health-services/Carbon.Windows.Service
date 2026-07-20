
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

Describe 'Tests' {
    $typeNames = @(
        'Carbon.Service.ErrorControl'
        'Carbon.Service.FailureAction'
        'Carbon.Service.ServiceInfo'
        'Carbon.Service.ServiceSecurity'
        'Carbon.Service.StartType'
        'Carbon.Security.ServiceAccessRights'
        'Carbon.Security.ServiceAccessRule'
    )
    It 'does not load <_>' -ForEach $typeNames {
        $loaded = $false
        try
        {
            [type]$_ | Out-Null
            $loaded = $true
        }
        catch
        {
        }

        $because = 'Tests are loading Carbon so no way to guarantee Carbon.Windows.Service isn''t still using Carbon ' +
                   'types.'
        $loaded | Should -BeFalse -Because $because
    }
}