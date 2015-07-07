
If (Test-Path "$PSScriptRoot\Apache.psm1"){
    Import-Module "$PSScriptRoot\Apache.psm1"
}
else{
    Write-Error "Couldn't find the Apache module"
}


