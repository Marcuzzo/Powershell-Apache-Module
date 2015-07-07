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

If (Test-Path "$PSScriptRoot\Apache.psm1"){
    Import-Module "$PSScriptRoot\Apache.psm1"
}
else{
    Write-Error "Couldn't find the Apache module"
}


