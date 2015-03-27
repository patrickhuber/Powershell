Import-Module PsGet
$scriptDirectory = $PSScriptRoot
$packageDirectory = ( $scriptDirectory | Split-Path -Parent )
Install-Module -ModulePath "$packageDirectory" -update -force