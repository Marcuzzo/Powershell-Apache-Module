
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
#try {
  
    # Intro
    Write-Host "`n`tRunning Tests on the Powershell Apache Module `n"

    # Test if the user is running in an elevated session
    Assert-Condition -Message "administrator rights`t`t`t" -Condition ( Test-Elevated ) 

    # Check if the Apache directory is found
    Assert-Condition -Message "Apache Directory`t`t`t" -Condition ( Test-ApacheDirectory) 

    # Check if the Apache httpd-vhosts.conf file is found
    Assert-Condition -Message "Apache Vhost file`t`t`t" -Condition ( Test-ApacheVhostsFile ) 

    Get-ApacheVirtualHost #-Name marcuzzo.local -verbose

    # Create a new Apache Virtual host file with the associated windows hosts entry
    [PSObject] $TestHost = New-ApacheVirtualHost -ServerName $sHostName -DocumentRoot $DocumentRoot -Force -AddToHosts

    
    Get-ApacheVirtualHost #-Name marcuzzo.local -verbose

    # check if the Virtual host was removed
    #Assert-Condition -Message "Virtual host removal`t`t`t" -Condition ( ( Get-ApacheVirtualHost -Filter { (( $_.ServerName -eq $sHostName ) -and ( $_.IPAddress -eq $sIPAddress ))} ) -eq $null )


    Write-Host "`n  End of testing`n`n"

#}
#catch {
#    Write-Host $_.Exception.Message -ForegroundColor Red 
#}
#finally {
#    # Remove the apache module to reset any changes in the module 
    Remove-Module Apache
#}
##endregion
