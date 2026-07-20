
function Install-CService
{
    <#
    .SYNOPSIS
    Installs a Windows service.

    .DESCRIPTION
    `Install-CService` uses `sc.exe` to install a Windows service. If a service with the given name already exists, it
    is stopped, its configuration is updated to match the parameters passed in, and then re-started. Settings whose
    parameters are omitted are reset to their default values.

    By default, the service is installed to run as `NetworkService`. Use the `Credential` parameter to run as a
    different account. This user will be granted the logon as a service right. To run as a system account other than
    `NetworkService`, provide just the account's name as the `UserName` parameter. [Managed service accounts and virtual
    accounts](http://technet.microsoft.com/en-us/library/dd548356.aspx) should be supported (we don't know how to test,
    so can't be sure). Pass their name to the `UserName` parameter.

    The minimum required information to install a service is its name and path.

    Manual services are not started. Automatic services are started after installation. If an existing manual service is
    running when configuration begins, it is re-started after re-configured. If a service is stopped when configuration
    begins, it remains stopped when configuration ends. To start the service if it is stopped, use the `-EnsureRunning`
    switch.

    .LINK
    Uninstall-CService

    .LINK
    http://technet.microsoft.com/en-us/library/dd548356.aspx

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe

    Installs the Death Star service, which runs the service executable at
    `C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe`.  The service runs as `NetworkService` and will start
    automatically.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -StartupType Manual

    Install the Death Star service to startup manually.  You certainly don't want the thing roaming the galaxy,
    destroying things willy-nilly, do you?

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -StartupType Automatic -Delayed

    Demonstrates how to set a service startup typemode to automatic delayed. Set the `StartupType` parameter to
    `Automatic` and provide the `Delayed` switch. This behavior was added in Carbon 2.5.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Credential $tarkin

    Installs the Death Star service to run as Grand Moff Tarkin, who is also given the log on as a service right.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -Username SYSTEM

    Demonstrates how to install a service to run as a system account, gMSA, or virtual account other than
    `NetworkService`. In this example, installs the DeathStar service to run as the local `System` account.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -OnFirstFailure RunCommand -RunCommandDelay '0:00:05' -Command 'engage_hyperdrive.exe "Corruscant"' -OnSecondFailure Restart -RestartDelay '00:00:30' -OnThirdFailure Reboot -RebootDelay '00:02:00' -FailureResetPeriod '1.00:00:00'

    Demonstrates how to control the service's failure actions. On the first failure, Windows will run the
    `engage-hyperdrive.exe "Corruscant"` command after 5 seconds. On the second failure, Windows will restart the
    service after 30 seconds. On the third failure, Windows will reboot after two minutes. The failure count gets reset
    once a day.

    .EXAMPLE
    Install-CService -Name DeathStar -Path C:\ALongTimeAgo\InAGalaxyFarFarAway\DeathStar.exe -EnsureRunning

    Demonstrates how to ensure a service gets started after installation/configuration. Normally, `Install-CService`
    leaves the service in whatever state the service was in. The `EnsureRunnnig` switch will attempt to start the
    service even if it was stopped to begin with.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='NetworkServiceAccount')]
    [OutputType([ServiceProcess.ServiceController])]
    param(
        # The name of the service.
        [Parameter(Mandatory)]
        [String] $Name,

        # The path to the service.
        [Parameter(Mandatory)]
        [String] $Path,

        # The arguments/startup parameters for the service. Added in Carbon 2.0.
        [String[]] $ArgumentList,

        # The startup type: automatic, manual, or disabled.  Default is automatic.
        #
        # To start the service as automatic delayed, use the `-Delayed` switch and set this parameter to `Automatic`.
        [ServiceStartMode] $StartupType = [ServiceStartMode]::Automatic,

        # When the startup type is automatic, further configure the service start type to be automatic delayed. This
        # parameter is ignored unless `StartupType` is `Automatic`.
        [switch] $Delayed,

        # What to do on the service's first failure. Default is to take no action.
        [Carbon_Windows_Service_FailureAction] $OnFirstFailure = [Carbon_Windows_Service_FailureAction]::None,

        # What to do on the service's second failure. Default is to take no action.
        [Carbon_Windows_Service_FailureAction] $OnSecondFailure = [Carbon_Windows_Service_FailureAction]::None,

        # What to do on the service' third failure. Default is to take no action.
        [Carbon_Windows_Service_FailureAction] $OnThirdFailure = [Carbon_Windows_Service_FailureAction]::None,

        # How often should the failure count get reset to 0? Default is to not set. Rounded to the nearest second.
        [TimeSpan] $FailureResetPeriod = [TimeSpan]::Zero,

        # How long to wait before restarting a service after a failure? Default is 1 minute.
        [TimeSpan] $RestartDelay = [TimeSpan]::New(0, 1, 0),

        # How long to wait before rebooting a server after a service failure? Default is 1 minute.
        [TimeSpan] $RebootDelay = [TimeSpan]::New(0, 1, 0),

        # What other services does this service depend on?
        [String[]] $Dependency,

        # The command to run when a service fails, including path to the command and arguments.
        [String] $FailureCommand,

        # How many milliseconds to wait before running the failure command. Default is 0, or immediately.
        [TimeSpan] $RunCommandDelay = [TimeSpan]::Zero,

        # The service's description. If you don't supply a value, the service's existing description is preserved.
        [String] $Description,

        # The service's display name. If you don't supply a value, the display name will set to Name.
        #
        # The `DisplayName` parameter was added in Carbon 2.0.
        [String] $DisplayName,

        [Parameter(ParameterSetName='CustomAccount', Mandatory)]
        [string]
        # The user the service should run as. Default is `NetworkService`.
        $UserName,

        [Parameter(ParameterSetName='CustomAccountWithCredential',Mandatory)]
        [pscredential]
        # The credential of the account the service should run as.
        #
        # The `Credential` parameter was added in Carbon 2.0.
        $Credential,

        [Switch]
        # Update the service even if there are no changes.
        $Force,

        [Switch]
        # Return a `System.ServiceProcess.ServiceController` object for the configured service.
        $PassThru,

        [Switch]
        # Start the service after install/configuration if it is not running. This parameter was added in Carbon 2.5.0.
        $EnsureRunning
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function ConvertTo-FailureActionArg($action)
    {
        if( $action -eq 'Reboot' )
        {
            return "reboot/{0}" -f [int]$RebootDelay.TotalMilliseconds
        }
        elseif( $action -eq 'Restart' )
        {
            return "restart/{0}" -f [int]$RestartDelay.TotalMilliseconds
        }
        elseif( $action -eq 'RunCommand' )
        {
            return 'run/{0}' -f [int]$RunCommandDelay.TotalMilliseconds
        }
        elseif( $action -eq 'None' )
        {
            return '""/0'
        }
        else
        {
            Write-Error "Service failure action '$action' not found/recognized."
            return ''
        }
    }

    function Select-FailureAction
    {
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [Object] $Action,

            [Parameter(Mandatory)]
            [int] $AtIndex
        )

        begin
        {
            $idx = 0
            $gotOne = $false
        }

        process
        {
            if ($idx++ -ne $AtIndex)
            {
                return
            }

            $gotOne = $true
            if ($null -eq $Action)
            {
                return [Carbon_Windows_Service_FailureAction]::None
            }

            return [Carbon_Windows_Service_FailureAction]$Action.Type
        }

        end
        {
            if (-not $gotOne)
            {
                return [Carbon_Windows_Service_FailureAction]::None
            }
        }

    }

    function Write-Change
    {
        param(
            [Parameter(Mandatory)]
            [String] $Property,

            [Parameter(Mandatory)]
            [AllowNull()]
            [AllowEmptyString()]
            [String] $OldValue,

            [Parameter(Mandatory)]
            [AllowNull()]
            [AllowEmptyString()]
            [String] $NewValue
        )

        Write-Verbose "[${Name}] $('{0,-19}' -f $Property)${OldValue} -> ${NewValue}"
    }

    function ConvertTo-ArgValue
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [AllowNull()]
            [AllowEmptyString()]
            [String] $InputObject
        )

        begin
        {
            Set-StrictMode -Version 'Latest'
            Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

            # How does PowerShell handle variables set to an empy string when part of a command?
            if ($null -eq $script:quotesEmptyStringArgs)
            {
                $emptyStringArg = ''
                $output = & (Join-Path -Path $script:moduleDirPath -ChildPath 'bin\args.exe') $emptyStringArg
                $script:quotesEmptyStringArgs = ($output | Measure-Object).Count -eq 1
                Write-Debug "quotesEmptyStringArgs  ${script:quotesEmptyStringArgs}"
            }
        }

        process
        {
            if ($script:quotesEmptyStringArgs -or $null -eq $InputObject)
            {
                return $InputObject
            }

            if ($InputObject -eq '')
            {
                return '""'
            }

            return $InputObject -replace '"', '\"'
        }
    }

    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' )
    {
        if( $PSCmdlet.ParameterSetName -like '*WithCredential' )
        {
            $UserName = $Credential.UserName
        }
        else
        {
            $Credential = $null
        }


        $identity = Resolve-CPrincipal -Name $UserName

        if( -not $identity )
        {
            Write-Error ("Identity '{0}' not found." -f $UserName)
            return
        }
    }
    else
    {
        $identity = Resolve-CPrincipal "NetworkService"
    }

    if( -not (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Warning ('Service ''{0}'' executable ''{1}'' not found.' -f $Name,$Path)
    }
    else
    {
        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty ProviderPath
    }


    if( $ArgumentList )
    {
        $binPathArg = Invoke-Command -ScriptBlock {
                            $Path
                            $ArgumentList
                        } |
                        ForEach-Object {
                            if( $_.Contains(' ') )
                            {
                                return '"{0}"' -f $_.Trim('"')
                            }
                            return $_
                        }
        $binPathArg = $binPathArg -join ' '
    }
    else
    {
        $binPathArg = $Path
    }

    $passwordArgMsg = ''
    $passwordArgName = $null
    $passwordArgValue = $null
    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' )
    {
        if( $Credential )
        {
            $passwordArgName = 'password='
            $password = $Credential.GetNetworkCredential().Password
            $passwordArgValue = $password | ConvertTo-ArgValue
            $passwordArgMsg = " ${passwordArgName} $('*' * $password.Length)"
        }

        if( $PSCmdlet.ShouldProcess( $identity.FullName, "grant the log on as a service right" ) )
        {
            Grant-CPrivilege -Identity $identity.FullName -Privilege SeServiceLogonRight
        }
    }

    if( $PSCmdlet.ShouldProcess( $Path, ('grant {0} ReadAndExecute permissions' -f $identity.FullName) ) )
    {
        Grant-CNtfsPermission -Identity $identity.FullName -Permission ReadAndExecute -Path $Path
    }

    $doInstall = $doFailureActions = $doDescription = $false
    if ($Force -or -not (Test-CService -Name $Name))
    {
        $doInstall = $doFailureActions = $doDescription = $true
    }
    else
    {
        Write-Debug -Message ('Service {0} exists. Checking if configuration has changed.' -f $Name)
        $service = Get-Service -Name $Name
        $serviceConfig = Get-CServiceConfiguration -Name $Name
        $dependedOnServiceNames =
            $service.ServicesDependedOn | Where-Object 'Name' -NE $Name | Select-Object -ExpandProperty 'Name'

        if( $serviceConfig.Path -ne $binPathArg )
        {
            Write-Change 'Path' -OldValue $serviceConfig.Path -NewValue $binPathArg
            $doInstall = $true
        }

        # DisplayName, if not set, defaults to the service name. This makes it a little bit tricky to update.
        # If provided, make sure display name matches.
        # If not provided, reset it to an empty/default value.
        if ($PSBoundParameters.ContainsKey('DisplayName'))
        {
            if( $service.DisplayName -ne $DisplayName )
            {
                Write-Change 'DisplayName' -OldValue $service.DisplayName -NewValue $DisplayName
                $doInstall = $true
            }
        }
        elseif ($service.DisplayName -ne $service.Name)
        {
            Write-Change 'DisplayName' -OldValue $service.DisplayName -NewValue ''
            $doInstall = $true
        }

        $firstFailure = $serviceConfig.FailureActions | Select-FailureAction -AtIndex 0
        if ($firstFailure -ne $OnFirstFailure)
        {
            Write-Change 'OnFirstFailure' -OldValue $firstFailure -NewValue $OnFirstFailure
            $doFailureActions = $true
        }

        $secondFailure = $serviceConfig.FailureActions | Select-FailureAction -AtIndex 1
        if ($secondFailure -ne $OnSecondFailure)
        {
            Write-Change 'OnSecondFailure' -OldValue $secondFailure -NewValue $OnSecondFailure
            $doFailureActions = $true
        }

        $thirdFailure = $serviceConfig.FailureActions | Select-FailureAction -AtIndex 2
        if ($thirdFailure -ne $OnThirdFailure)
        {
            Write-Change 'OnThirdFailure' -OldValue $thirdFailure -NewValue $OnThirdFailure
            $doFailureActions = $true
        }

        # Failure reset period is in seconds, so make sure TimeSpan is in seconds for change detection.
        $FailureResetPeriod = [TimeSpan]::New(0, 0, $FailureResetPeriod.TotalSeconds)
        if( $serviceConfig.FailureResetPeriod -ne $FailureResetPeriod )
        {
            Write-Change 'FailureResetPeriod' -OldValue $serviceConfig.FailureResetPeriod -NewValue $FailureResetPeriod
            $doFailureActions = $true
        }

        foreach ($actionType in @('Reboot', 'Restart', 'RunCommand'))
        {
            # RebootDelay, RestartDelay, and RunCommandDelay
            $varName = "${actionType}Delay"
            $expectedDelay = Get-Variable -Name $varName -ValueOnly
            $actions =
                $serviceConfig.FailureActions |
                Where-Object 'Type' -EQ $actionType |
                Where-Object 'Delay' -NE $expectedDelay
            if ($actions)
            {
                foreach ($action in $actions)
                {
                    Write-Change $varName -OldValue $action.Delay -NewValue $expectedDelay
                }
                $doFailureActions = $true
            }
        }

        # Cast $null to an empty string.
        if ([String]$serviceConfig.FailureCommand -ne $FailureCommand)
        {
            Write-Change 'FailureCommand' -OldValue $serviceConfig.FailureCommand -NewValue $FailureCommand
            $doFailureActions = $true
        }

        if( $service.StartType -ne $StartupType )
        {
            Write-Change 'StartupType' -OldValue $service.StartType -NewValue $StartupType
            $doInstall = $true
        }

        if( $StartupType -eq [ServiceProcess.ServiceStartMode]::Automatic -and $Delayed -ne $serviceConfig.DelayedAutoStart )
        {
            Write-Change 'DelayedAutoStart' -OldValue $serviceConfig.DelayedAutoStart -NewValue $Delayed
            $doInstall = $true
        }

        if( ($Dependency | Where-Object { $dependedOnServiceNames -notcontains $_ }) -or `
            ($dependedOnServiceNames | Where-Object { $Dependency -notcontains $_ })  )
        {
            Write-Change 'Dependency' -OldValue ($dependedOnServiceNames -join ',') -NewValue ($Dependency -join ',')
            $doInstall = $true
        }

        if( $Description -and $serviceConfig.Description -ne $Description )
        {
            Write-Change 'Description' -OldValue $serviceConfig.Description -NewValue $Description
            $doDescription = $true
        }

        $currentIdentity = Resolve-CPrincipal $serviceConfig.UserName
        if( $currentIdentity.FullName -ne $identity.FullName )
        {
            Write-Change 'UserName' -OldValue $currentIdentity.FullName -NewValue $identity.FullName
            $doinstall = $true
        }
    }

    try
    {
        if (-not $doInstall -and -not $doFailureActions -and -not $doDescription)
        {
            Write-Debug -Message ('Skipping {0} service configuration: settings unchanged.' -f $Name)
            return
        }

        $sc = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'sc.exe' -Resolve

        if( $Dependency )
        {
            $missingDependencies = $false
            foreach ($dependencyName in $Dependency)
            {
                if (-not (Test-CService -Name $dependencyName))
                {
                    $msg = "Dependent service ""${dependencyName}"" not found."
                    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                    $missingDependencies = $true
                }
            }
            if( $missingDependencies )
            {
                return
            }
        }

        $startArg = 'auto'
        if ($StartupType -eq [ServiceStartMode]::Automatic -and $Delayed)
        {
            $startArg = 'delayed-auto'
        }
        elseif ($StartupType -eq [ServiceStartMode]::Manual)
        {
            $startArg = 'demand'
        }
        elseif ($StartupType -eq [ServiceStartMode]::Disabled)
        {
            $startArg = 'disabled'
        }

        $service = Get-Service -Name $Name -ErrorAction Ignore

        $operation = 'create'
        $serviceIsRunningStatus = [ServiceControllerStatus]::Running, [ServiceControllerStatus]::StartPending

        if( -not $EnsureRunning )
        {
            $EnsureRunning = ($StartupType -eq [ServiceStartMode]::Automatic)
        }

        if( $service )
        {
            $EnsureRunning = ( $EnsureRunning -or ($serviceIsRunningStatus -contains $service.Status) )
            if ($StartupType -eq [ServiceStartMode]::Disabled)
            {
                $EnsureRunning = $false
            }

            if( $service.CanStop )
            {
                Stop-Service -Name $Name -Force -ErrorAction Ignore
                if( $? )
                {
                    $service.WaitForStatus( 'Stopped' )
                }
            }

            if (-not ($service.Status -eq [ServiceControllerStatus]::Stopped))
            {
                $msg = "Unable to stop service ""${Name}"" before applying configuration changes. You may need to " +
                       'restart this service manually for any changes to take affect.'
                Write-Warning $msg -WarningAction $WarningPreference
            }
            $operation = 'config'
        }

        $dependencyArgMsg = ''
        $dependencyArgName = $null
        $dependencyArgValue = $null
        if ($Dependency -or $doInstall)
        {
            $dependencyArgName = 'depend='
            $dependencyArgValue = $Dependency -join '/' | ConvertTo-ArgValue
            $dependencyArgMsg = " ${dependencyArgName} ${dependencyArgValue}"
        }

        $displayNameArgMsg = ''
        $displayNameArgName = $null
        $displayNameArgValue = $null
        if ($DisplayName -or $doInstall)
        {
            $displayNameArgName ='DisplayName='
            $displayNameArgValue = $DisplayName | ConvertTo-ArgValue
            $displayNameArgMsg = " ${displayNameArgName} ${displayNameArgValue}"
        }

        $target = "service ""${Name}"""
        $binPathArg = $binPathArg | ConvertTo-ArgValue
        if ($doInstall -and $PSCmdlet.ShouldProcess($target, $operation))
        {
            $msg = "${sc} ${operation} ${Name} binPath= ${binPathArg} start= ${startArg} obj= $($identity.FullName)" +
                   "${passwordArgMsg}${dependencyArgMsg}${displayNameArgMsg}"
            Write-Information $msg
            & $sc $operation `
                  $Name `
                  binPath= $binPathArg `
                  start= $startArg `
                  obj= $identity.FullName `
                  $passwordArgName $passwordArgValue `
                  $dependencyArgName $dependencyArgValue `
                  $displayNameArgName $displayNameArgValue |
                Write-Verbose
            $scExitCode = $LASTEXITCODE
            if( $scExitCode -ne 0 )
            {
                $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                if ($scExitCode -eq 1078)
                {
                    & $sc queryex $Name | Write-Verbose -Verbose
                    & $sc qc $Name | Write-Verbose -Verbose
                }
                Write-Error ("Failed to {0} service '{1}'. {2} returned exit code {3}: {4}" -f $operation,$Name,$sc,$scExitCode,$reason)
                return
            }
        }

        if ($doDescription -and $PSCmdlet.ShouldProcess($target, 'set description'))
        {
            Write-Information "${sc} description ${Name} ${Description}"
            & $sc 'description' $Name ($Description | ConvertTo-ArgValue) | Write-Verbose
            $scExitCode = $LASTEXITCODE
            if( $scExitCode -ne 0 )
            {
                $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                Write-Error ("Failed to set {0} service's description. {1} returned exit code {2}: {3}" -f $Name,$sc,$scExitCode,$reason)
                return
            }
        }

        $firstAction = ConvertTo-FailureActionArg $OnFirstFailure
        $secondAction = ConvertTo-FailureActionArg $OnSecondFailure
        $thirdAction = ConvertTo-FailureActionArg $OnThirdFailure

        $failureCommandArgValue = $FailureCommand | ConvertTo-ArgValue
        if ($doFailureActions -and $PSCmdlet.ShouldProcess($target, 'set failure actions'))
        {
            $failureResetPeriodSeconds = [int]$FailureResetPeriod.TotalSeconds
            $msg = "${sc} failure ${Name} reset= ${failureResetPeriodSeconds} " +
                   "${firstAction}/${secondAction}/${thirdAction} command= ${failureCommandArgValue}"
            Write-Information $msg
            & $sc failure `
                  $Name `
                  reset= $failureResetPeriodSeconds `
                  actions= $firstAction/$secondAction/$thirdAction `
                  command= $failureCommandArgValue |
                Write-Verbose
            $scExitCode = $LASTEXITCODE
            if( $scExitCode -ne 0 )
            {
                $reason = net helpmsg $scExitCode 2>$null | Where-Object { $_ }
                Write-Error ("Failed to set {0} service's failure actions. {1} returned exit code {2}: {3}" -f $Name,$sc,$scExitCode,$reason)
                return
            }
        }
    }
    finally
    {
        if( $EnsureRunning )
        {
            if( $PSCmdlet.ShouldProcess( $Name, 'start service' ) )
            {
                Start-Service -Name $Name -ErrorAction $ErrorActionPreference -WarningAction SilentlyContinue
                if( (Get-Service -Name $Name).Status -ne [ServiceControllerStatus]::Running )
                {
                    if( $PSCmdlet.ParameterSetName -like 'CustomAccount*' -and -not $Credential )
                    {
                        Write-Warning ('Service ''{0}'' didn''t start and you didn''t supply a password to Install-CService.  Is ''{1}'' a managed service account or virtual account? (See http://technet.microsoft.com/en-us/library/dd548356.aspx.)  If not, please use the `Credential` parameter to pass the account''s credentials.' -f $Name,$UserName)
                    }
                    else
                    {
                        Write-Warning ('Failed to re-start service ''{0}''.' -f $Name)
                    }
                }
            }
        }
        else
        {
            Write-Verbose ('Not re-starting {0} service. Its startup type is {1} and it wasn''t running when configuration began. To always start a service after configuring it, use the -EnsureRunning switch.' -f $Name,$StartupType)
        }

        if( $PassThru )
        {
            Get-Service -Name $Name -ErrorAction Ignore
        }
    }
}
