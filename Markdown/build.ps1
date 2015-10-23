param(
    [Parameter(Position = 0, Mandatory = $True)]
    [string] $startDirectory, 
    [Parameter(Position = 1, Mandatory = $True)]
    [string] $outputDirectory)
$ErrorActionPreference = "Stop"

function ConvertFrom-md($mdText){
  $response = Invoke-WebRequest -Uri 'https://api.github.com/markdown/raw' -Method Post -body "$mdText" -ContentType "text/plain"
  return $response.Content
}
 
function Md2Html
{ 
    param(
    [Parameter(Position = 0, Mandatory = $True)]
    [string] $filePath, 
    [Parameter(Position = 1, Mandatory = $True)]
    [string] $out)
     
    #get file name
    $fileWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

    #Get Text
    $content = (Get-Content $filePath)
    if($content -eq $null) { $content = ""}
    $mdt = [String]::Join([environment]::NewLine, $content); #Get-Content loses linebreaks for some reason.
 
    #Convert And Save to a temp file (warning, will overwrite)
    $htmlFile = [System.IO.Path]::Combine($out, "$fileWithoutExtension.html")
    if(test-path $htmlFile)
    {
        (ConvertFrom-md $mdt) | Out-File $htmlFile -Force
    }
    else
    {
        (ConvertFrom-md $mdt) | New-Item $htmlFile -ItemType file -Force
    }
}

function Recurse-Folder
{
    param(
    [Parameter(Position = 0, Mandatory = $True)]
    [string]$startDirectory, 
    [Parameter(Position = 1, Mandatory = $True)]
    [string]$outputDirectory)   

    $files = [System.IO.Directory]::EnumerateFiles($startDirectory, "*.md")
    foreach($file in $files)
    {
        md2html $file $outputDirectory
    }
    $subfolders = [System.IO.Directory]::EnumerateDirectories($startDirectory)
    foreach($subfolder in $subfolders)
    {        
        $subfolderName =  [System.IO.Path]::GetFileName($subfolder)
        $outSubfolder = [System.IO.Path]::Combine($outputDirectory, $subfolderName)        
        $startFolderPlusSubfolder = [System.IO.Path]::Combine($startDirectory, $subfolder)

        if(-not $startFolderPlusSubfolder.Equals($subfolder, [System.StringComparison]::InvariantCultureIgnoreCase))
        {
            Recurse-Folder $subfolder $outSubfolder
        }        
    }
}

function Resolve-PathWithScriptRoot
{
    param(
        [string]$directory
    )
    # if the source path is relative, join with the script root
    if(-not (split-path $directory -IsAbsolute))
    {
        return Join-Path $PSScriptRoot $directory
    }
    return $directory
}

# resolve inputs
$startDirectory = Resolve-PathWithScriptRoot $startDirectory
$outputDirectory = Resolve-PathWithScriptRoot $outputDirectory

# run the processing
Recurse-Folder $startDirectory $outputDirectory