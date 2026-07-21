
using namespace System.Security.AccessControl
using namespace System.Security.Principal
using namespace System.ServiceProcess

# Copyright WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

# Functions should use $script:moduleDirPath as the relative root from which to find things. A published module has its
# function appended to this file, while a module in development has its functions in the Functions directory.
$script:moduleDirPath = $PSScriptRoot

$script:numaEnabled = $null
#
$script:quotesEmptyStringArgs = $null

$modulesDirPath = Join-Path -Path $PSScriptRoot -ChildPath 'M' -Resolve

Import-Module -Name (Join-Path -Path $modulesDirPath -ChildPath 'PureInvoke\PureInvoke.psm1' -Resolve) `
              -Function @(
                    'Invoke-AdvApiOpenSCManager',
                    'Invoke-AdvApiOpenService',
                    'Invoke-AdvApiCloseServiceHandle',
                    'Invoke-AdvApiQueryServiceConfig',
                    'Invoke-AdvApiQueryServiceConfig2',
                    'Invoke-AdvApiQueryServiceObjectSecurity',
                    'Invoke-AdvApiSetServiceObjectSecurity',
                    'Write-Win32Error'
                ) `
              -Verbose:$false
Import-Module -Name (Join-Path -Path $modulesDirPath -ChildPath 'Carbon.Accounts\Carbon.Accounts.psm1' -Resolve) `
              -Function @('Resolve-CPrincipal') `
              -Verbose:$false
Import-Module -Name (Join-Path -Path $modulesDirPath -ChildPath 'Carbon.Security\Carbon.Security.psm1' -Resolve) `
              -Function @('Grant-CPrivilege') `
              -Verbose:$false
Import-Module -Name (Join-Path -Path $modulesDirPath -ChildPath 'Carbon.FileSystem\Carbon.FileSystem.psm1' -Resolve) `
              -Function @('Grant-CNtfsPermission') `
              -Verbose:$false

[Flags()]
enum Carbon_Windows_Service_ServiceAccessRights
{
    QueryConfig         = 0x00001
    ChangeConfig        = 0x00002
    QueryStatus         = 0x00004
    EnumerateDependents = 0x00008
    Start               = 0x00010
    Stop                = 0x00020
    PauseContinue       = 0x00040
    Interrogate         = 0x00080
    UserDefinedControl  = 0x00100
    Delete              = 0x10000
    ReadControl         = 0x20000
    WriteDac            = 0x40000
    WriteOwner          = 0x80000
    FullControl         = 0xf01ff
}

enum Carbon_Windows_Service_FailureAction
{
		None       = 0
		Restart    = 1
		Reboot     = 2
		RunCommand = 3
}

# Classes are cached by PowerShell. To support different versions of a class loaded side-by-side in the same PowerShell
# session, need to have a version number in the name.
class Carbon_Windows_Service_ServiceAccessRule_v1 : AccessRule
{
    Carbon_Windows_Service_ServiceAccessRule_v1([IdentityReference] $identity,
                                                [Carbon_Windows_Service_ServiceAccessRights] $rights,
                                                [AccessControlType] $type) :
        base($identity, [int]$rights, $false, [InheritanceFlags]::None, [PropagationFlags]::None, $type)
    {
        $this.ServiceAccessRights = $rights
    }

    [Carbon_Windows_Service_ServiceAccessRights] $ServiceAccessRights

    [bool] Equals([Object] $obj)
    {
        if ($null -eq $obj)
        {
            return $false
        }

        if ($obj -isnot [Carbon_Windows_Service_ServiceAccessRule_v1])
        {
            return $false
        }

        return $obj.ServiceAccessRights -eq $this.ServiceAccessRights -and `
               $obj.IdentityReference -eq $this.IdentityReference -and `
               $obj.AccessControlType -eq $this.AccessControlType
    }

    # https://github.com/microsoft/referencesource/blob/main/mscorlib/system/tuple.cs#L52-L55
    [int] CombineHashCodes([int] $h1, [int] $h2)
    {
        return (($h1 -shl 5) + $h1) -bxor $h2
    }

    [int] GetHashCode()
    {
        $h1 = $this.ServiceAccessRights.GetHashCode()
        $h2 = $this.IdentityReference.GetHashCode()
        $h3 = $this.AccessControlType.GetHashCode()

        $h = $this.CombineHashCodes($h1, $h2)
        return $this.CombineHashCodes($h, $h3)
    }
}

# Store each of your module's functions in its own file in the Functions directory. On the build server, your module's
# functions will be appended to this file, so only dot-source files that exist on the file system. This allows
# developers to work on a module without having to build it first. Grab all the functions that are in their own files.
$functionsPath = Join-Path -Path $script:moduleDirPath -ChildPath 'Functions\*.ps1'
if( (Test-Path -Path $functionsPath) )
{
    foreach( $functionPath in (Get-Item $functionsPath) )
    {
        . $functionPath.FullName
    }
}
