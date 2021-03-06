﻿<#
 This file is part of the Apache Powershell Module.

    the Apache Powershell Module is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    the Apache Powershell Module is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with the Apache Powershell Module.  If not, see <http://www.gnu.org/licenses/>.

#>

<#

    Description: Basic 'unit-testing' -ish script to test the module 

#>

If (Test-Path "$PSScriptRoot\Apache.psm1"){
    Import-Module "$PSScriptRoot\Apache.psm1"
}
else{
    Write-Host "not found"
}



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
  
    # Intro
    Write-Host "`n`tRunning Tests on the Powershell Apache Module `n"

    # Test if the user is running in an elevated session
    Assert-Condition -Message "administrator rights`t`t`t" -Condition ( Test-Elevated ) 

    # Check if the Apache directory is found
    Assert-Condition -Message "Apache Directory`t`t`t" -Condition ( Test-ApacheDirectory) 

    # Check if the Apache httpd-vhosts.conf file is found
    Assert-Condition -Message "Apache Vhost file`t`t`t" -Condition ( Test-ApacheVhostsFile ) 

    #Get-ApacheVirtualHost #-Name marcuzzo.local -verbose

    # Create a new Apache Virtual host file with the associated windows hosts entry
    [PSObject] $TestHost = New-ApacheVirtualHost -ServerName $sHostName -DocumentRoot $DocumentRoot -Force -AddToHosts 

    
    #Get-ApacheVirtualHost #-Name marcuzzo.local -verbose

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
