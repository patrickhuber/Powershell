param(
    [Parameter(Position = 0, Mandatory = $True)]
    [string] $startDirectory, 
    [Parameter(Position = 1, Mandatory = $True)]
    [string] $outputDirectory)

$ErrorActionPreference = "Stop"

. .\library.ps1

# resolve inputs
$startDirectory = Resolve-PathWithScriptRoot $startDirectory
$outputDirectory = Resolve-PathWithScriptRoot $outputDirectory

# run the processing
Generate-MarkdownSite $startDirectory $outputDirectory