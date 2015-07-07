<#
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
   Filename: Apache.psm1
   Description: Apache Virtual hosts Module
   Author: Marco Micozzi ( Marcuzzo )
   Date: 19/11/2014
#>


#region Variables
[string] $Script:ApacheDirectory = $null
#endregion Variables

#region INIT
# Create a directoryinfo object for the ScriptRoot
[System.IO.DirectoryInfo] $t = New-Object System.IO.DirectoryInfo -ArgumentList @(,$PSScriptRoot)


If ( Test-Path "$($t.Parent.FullName)\apache" )  {    
    $Script:ApacheDirectory = "$($t.Parent.FullName)\apache"
}
#endregion INIT

#region Constants 

# Declare a constant for the windows hosts file path
Set-Variable -Scope Script -Name HOSTFILE -Value "$env:windir\system32\drivers\etc\hosts" -Option Constant

# declare a constant for the localhost IP address
Set-Variable -Scope Script -Name LOCALHOST -Value '127.0.0.1'

# Declare a constant for the vhosts file
Set-Variable -Scope Script -Name VHOSTSFILE -Value 'conf\extra\httpd-vhosts.conf' -Option Constant

# Current Script version Constant 
Set-Variable -Scope Script -Name MODULE_VERSION -Value '0.3' -Option Constant

# The name of the apache service
Set-Variable -Scope Script -Name APACHE_SERVICE -Value 'Apache2.4' -Option Constant

Set-Variable -Scope Script -Name SERVICE_RUNNING -Value 'Running' -Option Constant

Set-Variable -Scope Script -Name SERVICE_STOPPED -Value 'Stopped' -Option Constant

Set-Variable -Scope Script -Name SERVICE_STARTING -Value 'Starting' -Option Constant

#endregion Constants

#region Test functions
<#
    This function tests if the current session is running elevated
#>
Function Test-Elevated{
    <#

    .SYNOPSIS 
     Checks if the current session is running with ele
     vated rights

    .DESCRIPTION
     This function will return a boolean value depending on the elevated state of the current session

     .EXAMPLE
     if ( Test-Elevated ) { Write-Host "You are running with elevated rights" }
#>
    Process {    
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent();
        $principal = new-object System.Security.Principal.WindowsPrincipal($identity);
        $AdminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;
        return [bool] $principal.IsInRole($AdminRole);   
    }
}



Function Test-ApacheDirectory{
[CmdLetBinding()]
param()


    Write-Verbose "Checking $Script:ApacheDirectory"
    If ( $Script:ApacheDirectory -eq $null ) {
        Write-Verbose "$Script:ApacheDirectory is not defined"
        return $false
    }

    if ( -not ( Test-Path -Path "$Script:ApacheDirectory" ) ) {
        Write-Verbose "The path '$Script:ApacheDirectory' doesn't exist"
        return $false    
    }
    Else{
        Write-Verbose "Apache directory found in: '$Script:ApacheDirectory'"
        return $true
    }

}


<# 
     Checks if the apache service is available/installed

#>
Function Test-ApacheService{
    Begin{    

       [String] $ServiceName = (Get-Variable -Name APACHE_SERVICE).Value

        return [bool] (Get-Service "$ServiceName" -ErrorAction SilentlyContinue)  
    }
}



Function Test-ApacheVhostsFile {    
     [CmdLetBinding()]
    param(
    )
    Begin {    
        # Get the vhosts subdirectory from the constant
        [String] $vhostsFile = ( Get-Variable -Name VHOSTSFILE -Scope Script ).Value        
        Write-Output ( Test-Path -Path "$($Script:ApacheDirectory)\$($vhostsFile)")
    }
}


#endregion


#region Windows Host 


Function Get-WindowsHost{
    <#

    .SYNOPSIS 
     Gets the hosts that are definded in the windows hosts file

    .DESCRIPTION
     This function will return all hosts that are defined in the local hosts file,
#>
    
    [CmdletBinding(DefaultParameterSetName = "none")]
    param(
        
        [Parameter( Position = 0, Mandatory = $False, ParameterSetName = "ByName" )]
        [string] $Name = $null,

        [Parameter( Position = 0, Mandatory = $false, ParameterSetName = "ByFilter" )]
        [ScriptBlock] $Filter = {}

    
    )


    Begin {
        
        # Create the AllHosts Array
        [PSObject[]] $AllHosts = @()

        [PSObject] $CurrentHost = $null

        # Get the path to the hosts file
        [String] $hostfile = (Get-Variable -Name HOSTFILE).Value

        $Member = @{
            MemberType = "NoteProperty"
            Force = $true
        } 
    
    }
    Process {
    
        # Make sure the hosts file exists
        if ( Test-Path -Path $hostfile ) {
        
            # Loop through the lines
            foreach ( $hostLine in ( Get-Content -Path $hostfile) ) {
            
                # Trim the current host line
                [String] $CurrentHostLine = $hostLine.Trim();

                # Only process lines that are not empty and not comment lines
                if ( ( ! ( [String]::IsNullOrEmpty($CurrentHostLine)) ) -and ( ! ( $CurrentHostLine.StartsWith('#')))) {
                    
                    # Split the line to get the ip address and the hostname
                    [String[]] $aHostData = $CurrentHostLine.Split(' ');

                    Write-Debug "aHostData Count: $($aHostData.Count)"

                    # only process array's that have 2 elements
                    if ( $aHostData.Count -eq 2 ){

                        # Create a new Object
                        $CurrentHost = New-Object PSObject

                        # Add the IPAddress property
                        $CurrentHost | Add-Member @Member -Name "IPAddress" -Value $aHostData[0].Trim();

                        # Add the HostName property
                        $CurrentHost | Add-Member @Member -Name "HostName" -Value $aHostData[1].Trim();
                        
                        # Add the Object to the AllHosts Object
                        $AllHosts += $CurrentHost

                    }   
                                     
                }   
                                  
            }   
                        
        }   
         
    }

    End {    

        if ( $PSCmdlet.ParameterSetName -eq 'ByName') {   

            Write-Output -InputObject $AllHosts | Where { $_.HostName -eq $Name }

        }        
        elseif ($PSCmdlet.ParameterSetName -eq 'ByFilter') {

            Write-Output -InputObject $AllHosts | Where $Filter

        }
        else
        {

            Write-Output -InputObject $AllHosts        

        }

    }

}



Function New-WindowsHost{
<#

    .SYNOPSIS 
     Adds a new host to the windows hosts file
    .DESCRIPTION
     This command adds a new Virtual host to the httpd-vhosts.conf file

    .PARAMETER InputObject
    PSObject returned by Get-Windowshost function.
    This is used by the Remove-WindowsHost function to recreate the file
    
    .PARAMETER HostName
    The name of the host

    .PARAMETER IPAddress
    The IP address of the host
          
    .OUPUTS
    
    .EXAMPLE
     New-WindowsHost -HostName 'SomeHostname'
      

#>
    [CmdletBinding(DefaultParameterSetName = "none")]
    param(

        [Parameter( Position = 0, Mandatory = $true,ParameterSetName = "InputObject", ValueFromPipeline=$true )]
        [ValidateNotNullOrEmpty()]
        [PSObject] $InputObject,
        
        [Parameter( Position = 0,Mandatory = $true,ParameterSetName = "ByName"  )]
        [Alias("HostName")]
        [String] $Name,

        [Parameter( Position = 1,Mandatory = $false,ParameterSetName = "ByName" )]
        [String] $IPAddress = (Get-Variable -Name LOCALHOST).Value
    )

    begin {
        
        # Make sure we are elevated
        If ( ! ( Test-Elevated ) ) {
            Throw { "You need to run this script with elevated rights!" }
        }
        
        [String] $hostfile = (Get-Variable -Name HOSTFILE).Value

        if ( ! ( Test-Path -Path $hostfile ) ) {
            New-Item -Path $hostfile -ItemType file -Force -Confirm:$false
            #Throw [System.IO.FileNotFoundException] "Can't find the hostfile"
        }

        # Make sure that the hostsfile is writable
        Try {
            Write-Debug "Trying to open: $hostfile"
            [io.file]::OpenWrite($hostfile).close() 
        }
        Catch { 
            Throw {"Can't write to hosts file!"}
        }
    }

    Process {

        # if the Windows host object is piped to the function, use the ip address and hostname
        if ( $InputObject -ne $null )
        {
            Write-Debug "From input: $($InputObject.IPAddress)"
            $IPAddress = $InputObject.IPAddress
            
            Write-Debug "From input: $($InputObject.HostName)"
            
            $Name = $InputObject.HostName
        }
               
       Write-Debug "Hostname: $Name"
       Write-Debug "IPAddress: $IPAddress"
       
       # try to get the host
       [PSObject] $CheckWindowsHost = Get-WindowsHost | Where-Object { ( ( $_.HostName -eq "$Name" ) -and ( $_.IPAddress -eq "$IPAddress" ) ) }
       
       # check if the host exists
       if ( $CheckWindowsHost ) {
            Write-Error "$Name already exists"
        }
        else
        {
            Write-Verbose "$Name doesn't exist"
            Add-Content -Path $hostfile -Value " $IPAddress $Name"
        }   
    }

    End{
        $NewWindowsHost = Get-WindowsHost | Where-Object { ( ( $_.IPAddress -eq "$IPAddress") -and ( $_.HostName -eq $HostName ) ) }
        Write-Output -InputObject $NewWindowsHost
    }
}

Function Remove-WindowsHost{
<#
    .SYNOPSIS 
     Removes a host to the windows hosts file

    .DESCRIPTION
     This command adds a new host to the Windows hosts file

    .PARAMETER InputObject
    PSObject returned by Get-Windowshost function.

    .PARAMETER HostName
    The name of the host to remove

    .PARAMETER IPAddress
    The IP address of the host to remove
          
    .EXAMPLE
   New-WindowsHost -HostName 'SomeHostname'
#>
    [CmdletBinding()]
    param(
        
        [Parameter( Position = 0, Mandatory = $true,ParameterSetName = "InputObject", ValueFromPipeline=$true,ValueFromPipeLineByPropertyName=$true  )]
        [ValidateNotNullOrEmpty()]
        [PSObject] $InputObject,

        [Parameter( Position = 0,Mandatory = $true,ParameterSetName = "ByName" )]
        [Alias("ServerName", "HostName")]
        [String] $Name,

        [Parameter( Position = 1,Mandatory = $false,ParameterSetName = "ByName" )]
        [String] $IPAddress = (Get-Variable -Name LOCALHOST).Value,

        [Switch] $Force

    )

    Begin {
        
         # Make sure we are elevated
        If ( ! ( Test-Elevated ) ) {
            Throw { "You need to run this script with elevated rights!" }
        }
        
        [String] $hostfile = (Get-Variable -Name HOSTFILE).Value

        # Make sure that the hostsfile is writable
        Try {
            Write-Debug "Trying to open: $hostfile"
            [io.file]::OpenWrite($hostfile).close() 
        }
        Catch { 
            Throw {"Can't write to hosts file!"}
        }

        # declare the host object
        [PSObject] $HostToRemove = $null

    }
    
    Process {
        
        # Check if the CmdLet received parameters or pipeline data
        if ( $PSCmdlet.ParameterSetName -eq 'ByName') {           
            
            # get the host by using the mandatory HostName and optional ( defaulted ) IP Address 
            $HostToRemove = Get-WindowsHost | Where-Object { ( ( $_.HostName -eq "$Name" ) -and ( $_.IPAddress -eq "$IPAddress" ) ) }        
        }
        else
        {            
            # use the object that was received through the pipeline
            $HostToRemove = $InputObject
        }

        # Get the path to the backup folder
        [String] $backupDir = "$($(get-item $hostfile).DirectoryName)"#\backup"

        # Create the backup folder if it doesn't exist
        if ( ! ( Test-Path -Path $backupDir ) ) {
            New-Item -Path $backupDir -ItemType Directory -Force -Confirm:$false | Out-Null
        }

        # Get the current Windows Hosts
        $WindowsHosts = Get-WindowsHost

        [String] $TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss";

        Write-Verbose "Backing up the hosts file"
        # a Copy/Remove is needed because the Rename Item has issues with the path
        Move-Item -Path $hostfile -Destination "$($backupDir)\host-$($TimeStamp).bak" -Force -Confirm:$false
        #Copy-Item -Path $hostfile -Destination "$($backupDir)\host-$($TimeStamp).bak" -Force -Confirm:$false
        #Remove-Item -Path $hostfile -Force -Confirm:$false        
        
        foreach ( $WindowsHost in $WindowsHosts ){
        
            if ( ( $WindowsHost.IPAddress -eq $HostToRemove.IPAddress ) -and ( $WindowsHost.HostName -eq $HostToRemove.HostName ) )
            {                
                Write-Debug "'$($WindowsHost.IPAddress)' VS '$($HostToRemove.IPAddress)'" 
                Write-Debug "'$($WindowsHost.HostName)' VS '$($HostToRemove.HostName)'"                
            }
            else 
            {            
                Write-Debug "'$($WindowsHost.IPAddress)' '$($WindowsHost.HostName)' remains"                 
                $WindowsHost | New-WindowsHost | Out-Null
                # New-WindowsHost -HostName $WindowsHost.HostName -IPAddress $WindowsHost.IPAddress | Out-Null
            }        

        }       
    }
    
    End {
        Write-Output -InputObject (Get-WindowsHost)
    }

}

#endregion Windows Host



#region Apache Virtual Host


Function Restart-ApacheService{
    
    Begin {

        # get the service name from the constant
        [String] $ServiceName = (Get-Variable -Name APACHE_SERVICE).Value
    
        # make sure the service exists
        if ( Test-ApacheService ){
        
            # get an object ref to the service controller
            [System.ServiceProcess.ServiceController] $Sc = Get-Service -Name "$ServiceName" 

            # make sure the service is running
            if ( $Sc.Status -eq (Get-Variable -Name SERVICE_RUNNING).Value ){
                
                # stop the service
                $Sc.Stop();
   
                # Wait for the service to have stopped
                 do{
                    # Refresh the Service Controller
                    $Sc.Refresh();
                    # Wait for 250 ms
                    Start-Sleep -Milliseconds 250
                    # Write debug info
                    Write-Debug "Service Status: $($Sc.Status)"
                
                } while ( $sc.Status -ne (Get-Variable -Name SERVICE_STOPPED).Value )

                #start the service
                $Sc.Start(); 

                               
                # Wait for the service to have the status 'Running'
                do{
                    # Refresh the Service Controller
                    $Sc.Refresh();
                    # Wait for 250 ms
                    Start-Sleep -Milliseconds 250
                    # Write debug info
                    Write-Debug "Service Status: $($Sc.Status)"
                
                } while ( $sc.Status -ne (Get-Variable -Name SERVICE_RUNNING).Value )

                # Dispose the Service Controller
                $Sc.Dispose();

                # Set the reference to NULL
                $Sc = $null
            }
            else {
                
                Write-Host "The apache service is not running"
            
            }
            
        
        }
        else
        {
            Throw "Apache Service Not available"
        }

    
    }

}

Function Get-ApacheVirtualHost{
<#

    .SYNOPSIS 
     Gets all virtual hosts that are defined in the apache vhosts.conf file

    .DESCRIPTION
     Gets all virtual hosts that are defined in the apache vhosts.conf file

    The Apache directory can be added as a parameter or can be piped to the function
    as a string.

    This parameter is mandatory because the function doesn't have any knowlegde of
    the location of the apache install directory

    .PARAMETER 
          
    .EXAMPLE
     Get-ApacheVirtualHosts 
     This command will print all the virtual hosts to the console    

     .OUTPUTS
#>
    [CmdletBinding(DefaultParameterSetName = "none")]
    param(

        [Parameter( Position = 0, Mandatory = $False, ParameterSetName = "ByName" )]
        [string] $Name = $null,

        [Parameter( Position = 0, Mandatory = $false, ParameterSetName = "ByFilter" )]
        [ScriptBlock] $Filter = {}

    )
    
    begin {
        
        Write-Debug "Beginnning $Script:ApacheDirectory "
       
        If ( -not ( $Script:ApacheDirectory )) {
            Write-Debug "Apache directory Not found"         
            throw "Apache Directory not found" 
        }


        # Declare a variable for each 'current' virtual host
        [PSObject] $VirtualHost = $null    

        # Declare the Directory object for the virtual host
        [PSObject] $Directory = $null

        # Declare the AllVirtualHosts Array
        [PSObject[]] $AllVirtualHosts = @()


        $Member = @{
            MemberType = "NoteProperty"
            Force = $true
        }    

        # Get the Localhost IP adddress from the constant
        [String] $localhost = ( Get-Variable -Name LOCALHOST -Scope Script ).Value

        # Get the vhosts subdirectory from the constant
        [String] $vhostsFile = ( Get-Variable -Name VHOSTSFILE -Scope Script ).Value

    } # End Begin

    Process {

        Write-Debug "ApacheDirectory: $Script:ApacheDirectory" 
        
        # Check if the apache directory exits and throw an error if it doesn't
        if ( ! ( Test-Path -Path "$Script:ApacheDirectory" ) ) {        
            throw "$Script:ApacheDirectory is not found"        
        }
        
        # Store the vhosts file's full path in a variable
        [String] $ConfFile = "$($Script:ApacheDirectory)\$($vhostsFile)";
        
        # Check if the vhosts file exits and throw an error if it doesn't
        if ( ! ( Test-Path -Path "$ConfFile" ) ) {        
            throw "$ConfFile is not found"        
        }

        # Get the contents of the vhosts file
        $ConfigLines = Get-Content -Path $ConfFile

        # Loop through all the lines
        foreach ( $ConfigLine in $ConfigLines ){
        
            # Trim the current line and store it in a variable
            [String] $currentLine = $ConfigLine.Trim();

            # skip empty lines
            if ( ! ( [String]::IsNullOrEmpty($currentLine) ) ){

                # Skip comments
                if ( ! ( $currentLine.StartsWith('#') ) ){
            
                    Write-Debug "Line: $currentLine"

                    # check if the VirtualHost close tag is found
                    if ( $currentLine.Equals('</VirtualHost>') ) {

                        # Add the virtual host to the collection
                        $AllVirtualHosts += $VirtualHost
                    }

                    # Check if the current line starts with the virtualhost tag
                    if ( $currentLine.StartsWith('<VirtualHost') ){

                        # Create a new PSObject for the current Virtual Host
                        $VirtualHost = New-Object PSObject

                        # Add the localhost IP Address
                        $VirtualHost | Add-Member @Member -Name "IPAddress" -Value $localhost

                        # Added apachedirectory so it can be reused in a pipeline
                        $VirtualHost | Add-Member @Member -Name "ApacheDirectory" -Value $Script:ApacheDirectory

                        # Add the custom log property, this way the property is there even when the custom log is not defined
                        # I added this to keep the object consistent
                        $VirtualHost | Add-Member @Member -Name "CustomLog" -Value ''
                    }

                    if ( $currentLine.StartsWith('ServerAdmin') ) {
                        $VirtualHost | Add-Member @Member -Name "ServerAdmin" -Value $currentLine.Substring("ServerAdmin".Length).Trim();
                    }

                    if ($currentLine.StartsWith('DocumentRoot' )){                        
                        $VirtualHost | Add-Member @Member -Name "DocumentRoot" -Value $currentLine.Substring('DocumentRoot'.Length).Trim().Replace('"', "")
                    }

                    # Get the ServerName
                    if ($currentLine.StartsWith('ServerName' )){
                        
                        # Add the property
                        $VirtualHost | Add-Member @Member -Name "ServerName" -Value $currentLine.Substring("ServerName".Length).Trim();

                        $IsHosted = ( ( Get-WindowsHost -Name $VirtualHost.ServerName ) -ne $null )

                        $VirtualHost | Add-Member @Member -Name "IsHosted" -Value $IsHosted

                    }
                    
                    if ($currentLine.StartsWith('ServerAlias' )){                        
                        $VirtualHost | Add-Member @Member -Name "ServerAlias" -Value $currentLine.Substring("ServerAlias".Length).Trim();
                    }
                    
                    if ($currentLine.StartsWith('ErrorLog' )){                        
                        $VirtualHost | Add-Member @Member -Name "ErrorLog" -Value $currentLine.Substring('ErrorLog'.Length).Trim().Replace('"', "")
                    }
                    
                    if ($currentLine.StartsWith('CustomLog' )){                        
                        
                        $VirtualHost.CustomLog = "$($currentLine.Substring('CustomLog'.Length).Trim())" #.Replace('"', "")
                        #$VirtualHost | Add-Member @Member -Name "CustomLog" -Value $currentLine.Substring('CustomLog'.Length).Trim() #.Replace('"', "")
                    }

                    if ( $currentLine.StartsWith('<Directory') ){    

                        # Create the new Directory Object                        
                        $Directory = New-Object psObject                                                                  

                        # Add the directory Property to the Virtual host
                        $VirtualHost | Add-Member -MemberType NoteProperty -Name 'Directory' -value $Directory                   
                        
                        # Set the Directory Path
                        $Directory | Add-Member @Member -Name 'Path' -Value $currentLine.Substring("<Directory ".Length).Trim().Replace(">", "").Replace('"', '');
                        
                    }

                    if ( $currentLine.StartsWith('AllowOverride') ){
                        $Directory | Add-Member @Member -Name "AllowOverride" -Value $currentLine.Substring("AllowOverride".Length).Trim();
                    }

                    if ( $currentLine.StartsWith('Order') ){
                        $Directory | Add-Member @Member -Name "Order" -Value $currentLine.Substring("Order".Length).Trim();
                    }

                    if ( $currentLine.StartsWith('Allow') ){
                        $Directory | Add-Member @Member -Name "Allow" -Value $currentLine.Substring("Allow".Length).Trim();
                    }

                    if ( $currentLine.StartsWith('Require') ){
                        $Directory | Add-Member @Member -Name "Require" -Value $currentLine.Substring("Require".Length).Trim();
                    }

                    if ( $currentLine.Equals('</Directory>') ){                        
                         
                        # Add the Directory Object to the Virtual host
                        $VirtualHost.Directory = $Directory                    

                    }

                }

            }   
                             
        }   

    } # End Process

    End {    

        if ( $PSCmdlet.ParameterSetName -eq 'ByName') {   

            #[String] $ScriptDir = Split-Path -Parent -Path "$($MyInvocation.MyCommand.Path)"
            Write-Verbose "Name: $Name Path: $($MyInvocation.MyCommand.Path)"

            $Invocation = (Get-Variable MyInvocation -Scope 1).Value;

            if($Invocation.PSScriptRoot)
            {
                Write-Verbose $Invocation.PSScriptRoot;
            }


            Write-Output -InputObject $AllVirtualHosts | Where-Object { $_.ServerName -eq $Name  }


        }
        
        elseif ($PSCmdlet.ParameterSetName -eq 'ByFilter') {
            Write-Verbose "Filter $Filter"
            Write-Output -InputObject $AllVirtualHosts | Where $Filter
        }
        else
        {  
            # Write the output to the pipe or output...
            Write-Output -InputObject $AllVirtualHosts
        
        }


        
         

        
    
        
    } # End Of End

}


Function New-ApacheVirtualHost{
<#

    .SYNOPSIS 
     Add a new virtual host to the apache vhosts.conf file

    .DESCRIPTION
     Add a new virtual host to the apache vhosts.conf file

    .PARAMETER ServerName
    The name of the server that needs to be added

    .PARAMETER ServerAdmin
    The name of the Server Administrator

    .PARAMETER DocumentRoot
    The DocumentRoot of the Virtual host

    .PARAMETER ServerAlias
    The Alias of the Server

    .PARAMETER ErrorLog
    The path to the error log

    .PARAMETER CustomLog
    The path to the custom log

    .PARAMETER Directory
    The directory used as DocumentRoot... this is defaulted to DocumentRoot

    .PARAMETER AllowOverride
    .PARAMETER Order
    .PARAMETER Allow
    .PARAMETER Require


    .PARAMETER Force
    Indicates that the DocumentRoot folder should be created if it doesn't exist

    .PARAMETER AddToHosts
    Indicates that the virtual host's name and ip address 
    should be added to the windows hosts file
    
          
    .EXAMPLE
    

#>
    [CmdletBinding(DefaultParameterSetName = "none")]
    param(

        [Parameter( Position = 0, Mandatory = $true,ParameterSetName = "InputObject", ValueFromPipeline=$true  )]
        [ValidateNotNullOrEmpty()]
        [PSObject] $InputObject,
        
        [Parameter(Position = 1,Mandatory = $true, ParameterSetName = "ByName") ]
        [Alias("ServerName")]
        [string] $Name,

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $ServerAdmin = $env:USERNAME,

        [Parameter(Position = 2,Mandatory = $true, ParameterSetName = "ByName") ]
        [String] $DocumentRoot,

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $ServerAlias = $Name, 

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $ErrorLog = "logs/$($Name)-error.log",

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $CustomLog = "logs/$($Name)-custom.log",

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $Directory = $DocumentRoot,

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $AllowOverride = 'All',

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $Order = 'allow,deny',

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $Allow = 'from all',

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [String] $Require = 'all granted',

        [Parameter(Mandatory = $false, ParameterSetName = "ByName") ]
        [Switch] $Force,

        [Switch] $WhatIf,

        [Switch] $AddToHosts
    )

    Begin {

        [String] $IPAddress = ( Get-Variable -Name LOCALHOST).Value
            
    }

    Process {

       if ( $InputObject ){

            $InputObject | Format-List -Property *

            Write-Debug "ApacheDir pipeline: $($InputObject.ApacheDirectory)"
            Write-Debug "ServerName pipeline: $($InputObject.ServerName)"

            $ApacheDirectory = $InputObject.ApacheDirectory
            $Name = $InputObject.ServerName
            $ServerAdmin = $InputObject.ServerAdmin
            $DocumentRoot = $InputObject.DocumentRoot
            $ServerAlias = $InputObject.ServerAlias
            $ErrorLog = $InputObject.ErrorLog
            $CustomLog = $InputObject.CustomLog
            $Directory = $InputObject.Directory.Path
            $AllowOverride  = $InputObject.Directory.AllowOverride
            $Order = $InputObject.Directory.Order
            $Allow = $InputObject.Directory.Allow
            $Require = $InputObject.Directory.Require
            
        
        }
      
        Write-Verbose  "ApacheDirectory: $Script:ApacheDirectory"

        # Check if the virtual host already exists
        # TODO: FIX THIS SHIT
        #$TestVirtualHost = Get-ApacheVirtualHost -Filter { ( $_.ServerName -eq "$Name" ) -and ( $_.DocumentRoot -eq "$DocumentRoot" ) } -Verbose
        $TestVirtualHost = Get-ApacheVirtualHost -Name $Name

       
        # Throw an error if found
        if ( $TestVirtualHost ) {
            [String] $ErrorMessage = "The Virtual Host $Name already exists!"
            Write-Host $ErrorMessage
            Throw { "Virtual Host already exists" }
        }
        else{
        Write-Host "not found...?"
            $TestVirtualHost | gm
        }


        # Check if documentroot exists
        if ( ! ( Test-Path -Path "$DocumentRoot" ) ) {
            # Document root doesn't exist                      

            # Check if the user wants to force the creation of the DocumentRoot
            if ( $Force.IsPresent ){

                Write-Verbose "DocumentRoot: $DocumentRoot doesn't exist, creating it"
                if ( $WhatIf.IsPresent ){
                    Write-Host "DocumentRoot: $DocumentRoot doesn't exist, creating it"
                }
                else{
                    # create the directory for the DocumentRoot
                    New-Item -Path $DocumentRoot -ItemType Directory -Force -Confirm:$false | Out-Null
                    '<h1>It Works</h1>' | Out-File "$($DocumentRoot)\index.html" -Confirm:$false 
                }
            }
            else
            {                                            
                Throw { "DocumentRoot doesn't exists!!!" }
            }
        }
        else
        {            
            Write-Verbose "DocumentRoot: $DocumentRoot found"                
        }


        [String] $VirtualHostText = "`n<VirtualHost *:80>`n"
        $VirtualHostText += "`tServerAdmin $ServerAdmin `n"
        $VirtualHostText += "`tDocumentRoot `"$DocumentRoot`"`n"
        $VirtualHostText += "`tServerName $Name`n"
        $VirtualHostText += "`tServerAlias $ServerAlias`n"
        $VirtualHostText += "`tErrorLog `"$ErrorLog`"`n"

        if ( ! ( [String]::IsNullOrEmpty($CustomLog) ) ) {
            
            if ( ! ( $CustomLog.EndsWith('comonvhost') ) ){
                $VirtualHostText += "`tCustomLog $CustomLog comonvhost`n"
             }
             else{
                $VirtualHostText += "`tCustomLog $CustomLog`n"
             }
#            $VirtualHostText += "`tCustomLog `"$CustomLog`"`n"
        }

        $VirtualHostText += "`t<Directory `"$Directory`">`n"
        $VirtualHostText += "`t`tAllowOverride $AllowOverride`n"
        $VirtualHostText += "`t`tOrder $Order`n"
        $VirtualHostText += "`t`tAllow $Allow`n"
        $VirtualHostText += "`t`tRequire $Require`n"
        $VirtualHostText += "`t</Directory>`n"
        $VirtualHostText += '</VirtualHost>`n'
           
        if ( $WhatIf.IsPresent ){
            Write-Host "Creating $Name with the following text: `n $VirtualHostText"
        }
        else
        {
                
            Add-Content -Path "$Script:ApacheDirectory\conf\extra\httpd-vhosts.conf" -Value $VirtualHostText
        }

        # Check if the
        if ( $AddToHosts.IsPresent){
            Write-Verbose "Adding host with $Name to the Windows host file"

            if ( ! ( Get-WindowsHost -Filter{ ( ( $_.HostName -eq $Name ) -and ( $_.IPAddress -eq $IPAddress ) ) } ) ) {
                New-WindowsHost -Name $Name #| Out-Null
            }
            else
            {
                Write-Verbose "The Host with Name $Name already exists in the Windows Host File"
            }
        }
            
    }

    End {
        if ( ! ( $WhatIf.IsPresent ) ) {
            $NewVirtualHost = Get-ApacheVirtualHost -Filter { ( $_.ServerName -eq "$Name" ) -or ( $_.DocumentRoot -eq "$DocumentRoot" )} 
            Write-Output -InputObject $NewVirtualHost
        }
    }    
}



# TODO: Finish this!
Function Remove-ApacheVirtualHost{

 [CmdletBinding( SupportsShouldProcess=$true, ConfirmImpact="High")]
    param(
    
        [Parameter( Position = 0, Mandatory = $true,ParameterSetName = "InputObject", ValueFromPipeline=$true,ValueFromPipeLineByPropertyName=$true  )]
        [ValidateNotNullOrEmpty()]
        [PSObject] $InputObject,
        
        [Parameter( Position = 1,Mandatory = $true,ParameterSetName = "ByName" )]
        [Alias("ServerName")]
        [String] $Name,

        [Parameter( Position = 2,Mandatory = $true,ParameterSetName = "ByName" )]
        [Alias("DocRoot")]
        [String] $DocumentRoot,

        [Switch] $Force
    )

    Begin {

        [String] $vhostfile = ( Get-Variable -Name VHOSTSFILE ).Value

        [PSObject] $VirtualHostToRemove = $null

    }

    Process {
        
        if ( $InputObject ) {
            
            Write-Verbose "Getting info from pipeline"

            Write-Verbose "Removing: $($InputObject.ServerName)"
            Write-Verbose "Removing: $($InputObject.ApacheDirectory)"

            $VirtualHostToRemove = $InputObject 
      
        }
        else 
        {
            Write-Verbose "Getting info from parameters"

            # try to get the object of the current requested virtual host
            $tmpVirtualHost = Get-ApacheVirtualHost | Where-Object { ( ( $_.ServerName -eq $Name ) -and ( $_.DocumentRoot -eq $DocumentRoot ) ) }

            # check if the object is fetched and assign it to the VirtualHostToRemove object
            if ( $tmpVirtualHost ) {                
                $VirtualHostToRemove = $tmpVirtualHost            
            }
            else
            {
                Throw {"Couldn't Find the requested Host"}            
            }

        }

        if ($pscmdlet.ShouldProcess("$($VirtualHostToRemove.ApacheDirectory)\$($vhostfile)", "Remove Virtual Host '$($VirtualHostToRemove.ServerName)'")) {
            
            Write-Verbose "Removing!!!"
            
             # Get the path to the backup folder
            [String] $backupDir = "$($(get-item "$($VirtualHostToRemove.ApacheDirectory)\$($vhostfile)").DirectoryName)\backup"

            # Create the backup folder if it doesn't exist
            if ( ! ( Test-Path -Path $backupDir ) ) {
                New-Item -Path $backupDir -ItemType Directory -Force -Confirm:$false | Out-Null
            }

            [String] $TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss";

            Write-Verbose "$($VirtualHostToRemove.ApacheDirectory)\$($vhostfile)"
            Write-Verbose "$($backupDir)\httpd-vhosts-$($TimeStamp).conf"

            [String] $original_vhostsfile = "$($VirtualHostToRemove.ApacheDirectory)\$($vhostfile)"
            [String] $backup_vhostsfile = "$($backupDir)\httpd-vhosts-$($TimeStamp).conf"

            [PSObject] $VirtualHosts = Get-ApacheVirtualHost 

            # Move the file to the backup
            Move-Item -Path $original_vhostsfile -Destination $backup_vhostsfile -Force -Confirm:$false

            $sVhostHeader = @"
 # Apache virtual Hosts Configuration file
 # This file was generated by the Powershell Apache Module
 # Version:	$((Get-Variable -Name MODULE_VERSION).Value)
 # Date:		$TimeStamp
 NameVirtualHost *:80
"@

            # Write the header to the vhosts file.
            # UTF-8 encoding is needed because apache will not be able to read the file
            $sVhostHeader | Out-File $original_vhostsfile -Encoding utf8

            # Loop through all the virtual hosts 
            foreach ( $virtualhost in $VirtualHosts) {
            
                # Check if the 'current' Virtual host is the one we want to remove
                if ( ( $virtualhost.ServerName -eq $VirtualHostToRemove.ServerName ) -and ( $virtualhost.DocumentRoot -eq $VirtualHostToRemove.DocumentRoot ) )
                {                
                    
                    # This is the Virtual host we want to remove, so we do... nothing...
                    Write-Debug "'$($virtualhost.ServerName)' VS '$($VirtualHostToRemove.ServerName)'" 

                    Write-Debug "'$($virtualhost.DocumentRoot)' VS '$($VirtualHostToRemove.DocumentRoot)'"            
                    
                    Write-Verbose "Removing: $($virtualhost.ServerName)"    

                }
                else 
                {          
                
                    # This is a virtual host we want to keep, so we recreate the virtual host and add it to the vhosts file
                      
                    Write-Verbose "'$($virtualhost.ServerName)' '$($virtualhost.DocumentRoot)' on '$($virtualhost.ApacheDirectory)' remains"                 
                    
                    # TGFTPL, Pipe the Current Virtual host to the New-ApacheVirtualHost CmdLet
                    $virtualhost | New-ApacheVirtualHost | Out-Null

                }                    
            }
        } 
    }

    End {    
    }    
}

#endregion Apache Virtual Host

# Export the functions
Export-ModuleMember -Function * #-Variable $Global:ApacheDirectory 
