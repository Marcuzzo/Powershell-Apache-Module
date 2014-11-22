#  Powershell Apache Module #
This is my first attempt in creating a powershell module.
I moved from VBS and JScript for my automation scripts to Powershell recently so please go easy on me;

This Module consists of a set of functions to get and set virtual hosts in the apache vhosts.conf file and in the windows hosts file.

I've added Test-Apache.ps1 to the repository to run a few tests. 

### Requirements
Because some of the functions will read from and write to a file in the system32 directory you need to be running it with elevated permissions. 

These functions have been tested on a Windows 8.1 machine:

	Major  Minor  Build  Revision
	-----  -----  -----  --------
	6      3      9600   0


 with the following $PSVersionTable info:

	Name                           Value
	----                           -----
	PSVersion                      4.0
	WSManStackVersion              3.0
	SerializationVersion           1.1.0.1
	CLRVersion                     4.0.30319.34014
	BuildVersion                   6.3.9600.17090
	PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0}
	PSRemotingProtocolVersion      2.2
  


I've only tested this with apache that comes with XAMPP but I'm not expecting any mayor changes for other Apache MySQL and PHP packages

### License
This module and it's additional files are distributed under the GNU General Public License v3.

### Contribute
If you want to contribute to this Powershell module or if you have any ideas to improve it please fork it and make send me a pull request.

## Functions
### Get-ApacheVirtualHost
The Get-ApacheVirtualHost function will return all virtual hosts that have been configured in the file httpd-vhosts.conf which is located in the 'conf/extra' subdirectory of the apache installation directory.  

The Get-ApacheVirtualHost function has 1 mandatory parameter which is `ApacheDirectory` :

    Get-ApacheVirtualHost -ApacheDirectory "C:\xampp\apache"

The `ApacheDirectory` parameter can also be piped to the function

	"C:\xampp\apache" | Get-ApacheVirtualHost


#### Filtering
At the moment I haven't added a -Filter parameter yet but I will try to add this when I have more time.  
You can use the `Where-Object` CmdLet to filter the output.
  
to get all the virtual hosts that start with 'test' you can run the following:

```PowerShell
	Get-ApacheVirtualHost -ApacheDirectory "C:\xampp\apache" | Where-Object { $_.ServerName -like 'test*' }
 ```
 
#### Output
The Get-ApacheVirtualHost function will return an object of Type PSCustomObject.

	PS C:\CmdLets\Apache-Vhost> Get-ApacheVirtualHost -ApacheDirectory C:\xampp\apache | Get-Member

       TypeName: System.Management.Automation.PSCustomObject

    Name 			MemberType   	Definition
    ---- 			----------   	----------
    Equals   		Method   		bool Equals(System.Object obj)
    GetHashCode  	Method   		int GetHashCode()
    GetType  		Method   		type GetType()
    ToString 		Method   		string ToString()
    Directory		NoteProperty 	System.Management.Automation.PSCustomObject
    DocumentRoot 	NoteProperty 	System.String
    ErrorLog 		NoteProperty 	System.String
    ServerAdmin  	NoteProperty 	System.String
    ServerAlias  	NoteProperty 	System.String
    ServerName   	NoteProperty 	System.String

The Directory Object:

	PS C:\CmdLets\Apache-Vhost> (Get-ApacheVirtualHost -ApacheDirectory C:\xampp\apache).Directory | Get-Member

	   TypeName: System.Management.Automation.PSCustomObject

	Name  			MemberType   	Definition
	----  			----------   	----------
	Equals			Method   		bool Equals(System.Object obj)
	GetHashCode   	Method   		int GetHashCode()
	GetType   		Method   		type GetType()
	ToString  		Method   		string ToString()
	Allow 			NoteProperty 	System.String
	AllowOverride 	NoteProperty 	System.String
	Order 			NoteProperty 	System.String
	Path  			NoteProperty 	System.String
	Require 		NoteProperty 	System.String



### New-ApacheVirtualHost 

The New-ApacheVirtualHost will add a new virtual host to the httpd-vhosts.conf file.

#### Syntax

	New-ApacheVirtualHost [-InputObject] <PSObject> [-WhatIf] [<CommonParameters>]

	New-ApacheVirtualHost [-ApacheDirectory] <String> [-ServerName] <String> [-ServerAdmin <String>]
	                      [-DocumentRoot] <String> [-ServerAlias <String>] [-ErrorLog <String>]
	                      [-CustomLog <String>] [-Directory <String>] [-AllowOverride <String>] [-Order <String>]
	                      [-Allow <String>] [-Require <String>] [-Force] [-WhatIf] [<CommonParameters>]

#### Example

	New-ApacheVirtualHost -ApacheDirectory "C:\Xampp\apache" `
	                      -ServerName "SomeHost.local" `
	                      -DocumentRoot "C:\sites\SomeHost.local"


This will create the following Virtual host in the vhosts.conf file:  

     <VirtualHost *:80>
    	ServerAdmin Marcuzzo
    	DocumentRoot "C:\sites\SomeHost.local"
    	ServerName SomeHost.local
    	ServerAlias SomeHost.local
    	ErrorLog "logs/SomeHost.local-error.log"
    	CustomLog "logs/SomeHost.local-custom.log"
    	<Directory "C:\sites\SomeHost.local">
    		AllowOverride All
    		Order allow,deny
    		Allow from all
    		Require all granted
    	</Directory>
    </VirtualHost>

This Function will return the PSObject of the created virtual host  


### Remove-ApacheVirtualHost
There are 2 ways to remove a Virtual host:   

1. by using the `Name` and `DocumentRoot` parameters.  
2. by piping the output of the `Get-ApacheVirtualHost` to the `Remove-ApacheVirtualHost` Cmdlet

#### Syntax

    Remove-ApacheVirtualHost [-ApacheDirectory] <string> [-Name] <string> [-DocumentRoot] <string> [-Force] [-WhatIf] [-Confirm]  [<CommonParameters>]

    Remove-ApacheVirtualHost [-InputObject] <psobject> [-Force] [-WhatIf] [-Confirm]  [<CommonParameters>]



#### Example

Parameters:

	Remove-ApacheVirtualHost -ApacheDirectory "C:\Xampp\apache" -Name "SomeHost.local" -DocumentRoot "C:\sites\SomeHost.local" -Confirm:$false


Pipeline:

	$ApacheDir | Get-ApacheVirtualHost | Where-Object { $_.ServerName -eq "SomeHost.local"  } | Remove-ApacheVirtualHost -Confirm:$false

> See the Test-Apache.ps1 script for a working example



### Get-WindowsHost
To get all WindowsHosts run:

	Get-WindowsHost | Format-Table

To get a specific host you can use the Where-Object CmdLet
	
	Get-WindowsHost | Where-Object { $_.HostName -eq 'SomeHost.local' }

### Output

	PS C:\CmdLets\Apache-Vhost> Get-WindowsHost | gm
		
	   TypeName: System.Management.Automation.PSCustomObject
	
	Name        MemberType   Definition
	----        ----------   ----------
	Equals      Method       bool Equals(System.Object obj)
	GetHashCode Method       int GetHashCode()
	GetType     Method       type GetType()
	ToString    Method       string ToString()
	HostName    NoteProperty System.String HostName=SomeHost.local
	IPAddress   NoteProperty System.String IPAddress=127.0.0.1

### New-WindowsHost

to Create a new Host with the localhost IP Addres and the name SomeHost.local use:

	New-WindowsHost -Name "SomeHost.local"

The function also accepts a PSObject through the pipeline. this is used by the Remove-WindowsHost Function:

	$oWindowsHost | New-WindowsHost


### Remove-WindowsHost

You can remove a WindowsHost by using the -(Host)Name and the optional IPAddress Parameter.

	Remove-WindowsHost -Name "SomeHost.local"

Or you can get the Host object using the Get-WindowsHost function and pipe it to the Remove-WindowsHost Function
	
	Get-WindowsHost | Where-Object { $_.HostName -eq 'SomeHost.local' } | Remove-WindowsHost 