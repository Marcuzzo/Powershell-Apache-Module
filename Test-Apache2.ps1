<#
    This file is part of Powerhell Apache Module.

    Powerhell Apache Module is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Powerhell Apache Module is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
#>

# The path to Apache
# SET THIS TO THE CORRECT PATH ON YOUR MACHINE
[String] $ApacheDir = 'C:\Utilities\xampp\apache'

#region Test Variables

# The current Script directory
[String] $ScriptDir = Split-Path -Parent -Path "$($MyInvocation.MyCommand.Definition)"

# IP Address for local host
[String] $sIPAddress = '127.0.0.1'

# The dummy hostname that will be created and deleted
[String] $sHostName = 'DummyHost.local'

# the fake document root for our new virtual host
[string] $DocumentRoot = 'C:\sites\DummyHost.local'

#endregion


#region Function(s)
<# 
    Simple 'unit testing' -ish function for quick testing
#>
Function Assert-Condition{    
    param (        
        [String] $Message,
        [boolean] $Condition    
    )
     Write-host "  Testing $($Message): " -NoNewline
     if ( $Condition ) {
        Write-Host "Success" -ForegroundColor Green
    }
    else
    {
        Write-Host "FAIL!" -ForegroundColor Red
    }
}
#endregion

#region Actual testing
try {
  
    # import the Apache Module
    Import-Module "$($ScriptDir)\Apache.psm1"

    # Intro
    Write-Host "`n`tRunning Tests on the Powershell Apache Module `n"

    # Test if the user is running in an elevated session
    Assert-Condition -Message "administrator rights`t`t`t" -Condition ( Test-Elevated ) 

    # Check if the Apache directory is found
    Assert-Condition -Message "Apache Directory`t`t`t" -Condition ( Test-ApacheDirectory -Path $ApacheDir ) 

    # Check if the Apache httpd-vhosts.conf file is found
    Assert-Condition -Message "Apache Vhost file`t`t`t" -Condition ( Test-ApacheVhostsFile -Path $ApacheDir ) 

    $ApacheDir | Get-ApacheVirtualHost -Name marcuzzo.local -verbose
    # check if the Virtual host was removed
    Assert-Condition -Message "Virtual host removal`t`t`t" -Condition ( ( Get-ApacheVirtualHost -ApacheDirectory $ApacheDir | Where-Object { (( $_.ServerName -eq $sHostName ) -and ( $_.IPAddress -eq $sIPAddress ))} ) -eq $null )


    Write-Host "`n  End of testing`n`n"

}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red 
}
finally {
    # Remove the apache module to reset any changes in the module 
    Remove-Module Apache
}
#endregion