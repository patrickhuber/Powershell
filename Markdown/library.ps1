$ErrorActionPreference = "Stop"

function Generate-MarkdownSite
{
    param(
    [Parameter(Position = 0, Mandatory = $True)]
    [string]$startDirectory, 
    [Parameter(Position = 1, Mandatory = $True)]
    [string]$outputDirectory,
    [Parameter(Position = 2, Mandatory = $false)]
    [string]$rootDirectory = $PSScriptRoot)   

    $files = [System.IO.Directory]::EnumerateFiles($startDirectory, "*.md")
    $layoutHashTable = Get-LayoutContentHashTable $rootDirectory
    foreach($file in $files)
    {
        md2html $layoutHashTable $file $outputDirectory
    }
    $subfolders = [System.IO.Directory]::EnumerateDirectories($startDirectory)
    foreach($subfolder in $subfolders)
    {        
        $subfolderName =  [System.IO.Path]::GetFileName($subfolder)
        $outSubfolder = [System.IO.Path]::Combine($outputDirectory, $subfolderName)        
        $startFolderPlusSubfolder = [System.IO.Path]::Combine($startDirectory, $subfolder)

        if(-not $startFolderPlusSubfolder.Equals($subfolder, [System.StringComparison]::InvariantCultureIgnoreCase))
        {
            Generate-MarkdownSite $subfolder $outSubfolder
        }        
    }
}

function Md2Html
{ 
    param(
    [Parameter(Position = 0, mandatory = $true)]
    [hashtable] $layoutHashTable,
    [Parameter(Position = 1, Mandatory = $True)]
    [string] $filePath, 
    [Parameter(Position = 2, Mandatory = $True)]
    [string] $outPath)
     
    # get file name
    $fileWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

    # Get Content
    $content = (Get-Content $filePath)
    if($content -eq $null) { $content = ""}
    $content = [String]::Join([environment]::NewLine, $content); #Get-Content loses linebreaks for some reason.

    # Get Metadata
    $page = Get-MarkdownMetaData $content

    # Remove Metadata from content
    $content = Remove-MarkdownMetaData $content
    
    # Grab the content of the layout file and use it as a template when generating the html content
    $layout = if ($layoutHashTable.ContainsKey($page.layout)) { 
        $layoutHashTable[$page.layout]
    } 
    else {
        $layoutHashTable["default"]
    }
    $content = ConvertFrom-md $content

    # generate the document by expanding strings within it
    $document = $ExecutionContext.InvokeCommand.ExpandString($layout)

    #Convert And Save to a temp file (warning, will overwrite)
    $htmlFile = [System.IO.Path]::Combine($outPath, "$fileWithoutExtension.html")
    
    if(test-path $htmlFile)
    {
        $document | Out-File $htmlFile -Force | Out-Null
    }
    else
    {
        $document | New-Item $htmlFile -ItemType file -Force | Out-Null
    }
}

function ConvertFrom-md
{
    param(
        [string] $mdText
    )
    $response = Invoke-WebRequest -Uri 'https://api.github.com/markdown/raw' -Method Post -body "$mdText" -ContentType "text/plain" -UseBasicParsing
    return $response.Content
}

function Get-MarkdownMetaData
{
    param(
        [string] $markdownContent
    )
    $array = $markdownContent -split "\r\n?|\n"
    $currentState = 0
    $metadata = @{}
    foreach($line in $array){
        switch($currentState){
            0 {
                if($line.StartsWith("---")){
                    $currentState = 1
                }
            }
            1 {
                if($line.StartsWith("---")){
                    $currentState = 2
                }
                else{
                    $fields = $line -split ":", 2                      
                    $metadata[$fields[0]] = $fields[1].Trim()
                }
            }
            2{
                break
            }
        }
    }
    
    return New-Object –TypeName PSObject -Property $metadata
}

function Remove-MarkdownMetaData
{
    param(
        [string] $markdownContent
    )
    $result = [System.Text.StringBuilder]::new()
    $array = $markdownContent -split "\r\n?|\n"
    $currentState = 0
    foreach($line in $array)
    {
        switch($currentState)
        {
            0 { 
                if($line.StartsWith("---")){
                    $currentState = 1 
                }
                else {
                    [void]$result.AppendLine($line)
                }
            }
            1 { 
                if($line.StartsWith("---")){
                    $currentState = 2
                } 
            }
            2 {
                [void]$result.AppendLine($line)
            }
        }
    }
    return $result.ToString()
}

function Get-DefaultLayoutContent
{
    $stringBuilder = [System.Text.StringBuilder]::new()
    [void]$stringBuilder.AppendLine("<!DOCTYPE html>")
    [void]$stringBuilder.AppendLine("<html>")
    [void]$stringBuilder.AppendLine("`t<head>")
    [void]$stringBuilder.AppendLine("`t`t<meta http-equiv=""X-UA-Compatible"" content=""IE=edge""> ")
    [void]$stringBuilder.AppendLine("`t`t<meta charset=""UTF-8"">")
    [void]$stringBuilder.AppendLine('`t`t<title>${page.title}</title>')
    [void]$stringBuilder.AppendLine("`t</head>")
    [void]$stringBuilder.AppendLine("`t<body>")
    [void]$stringBuilder.AppendLine('`t`t${content}')
    [void]$stringBuilder.AppendLine("`t</body>")
    [void]$stringBuilder.AppendLine("</html>")
    $content = $stringBuilder.ToString()
    return $content
}

<#
.description
------------
Gets the layout files in specified directory, 
trims the names 
and loads them into a hashtable with the contents

 #>
function Get-LayoutContentHashTable 
{
    param(
        [string]$directory,
        [string]$pattern = "_layout"
    )
    try{
        $layoutDirectory = Get-ChildItem -Path $directory -Filter "_layout"
        $files = Get-ChildItem -Path $layoutDirectory -Filter "*.html"
        $hashTable = @{}
        foreach($file in $files){
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.FullName)
            $hashTable[$fileName] = Get-Content -Path $file.FullName -Raw
        }
        return $hashTable
    }
    catch [System.Exception]{         
        $content = Get-DefaultLayoutContent
        return @{ "default" = $content }
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

function UploadRecursive($targetUri, $path, $filter = "*.*")
{
    Upload -targetUri $targetUri -path $path -filter $filter
    $folders = Get-ChildItem $path | ?{ $_.PSIsConttainer }

    foreach($folder in $folders)
    {
        $childUri = Join-Uri -uri $targetUri -childPath $folder.Name
        UploadRecursive -targetUri $childUri -path $folder.FullName -filter $filter
    }
}

function Upload($targetUri, $path, $filter)
{
    $files = Get-ChildItem $path -Filter $filter | ?{ -not $_.PSIsContainer }
    foreach($file in $files)
    {
        Publish-File -url $targetUri -files @($file)
    }    
}

<# Joins uri to a child path#>
function Join-Uri
{
    [CmdletBinding(DefaultParametersetName="Uri")]    
    param(
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=0)]
        [uri]$uri, 
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=1)]
        [string]$childPath)
    $combinedPath = [system.io.path]::Combine($uri.AbsoluteUri, $childPath)
    $combinedPath = $combinedPath.Replace('\', '/')
    return New-Object uri $combinedPath
}

# http://poshcode.org/2122
# Note that this version will not descend directories.
function Publish-File {
    param (
            [parameter( Mandatory = $true, HelpMessage="URL pointing to a SharePoint document library (omit the '/forms/default.aspx' portion)." )]
            [System.Uri]$Url,
            [parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage="One or more files to publish. Use 'dir' to produce correct object type." )]
            [System.IO.FileInfo[]]$files,
            [system.Management.Automation.PSCredential]$Credential
    )
    $wc = new-object System.Net.WebClient
    if ( $Credential ) { $wc.Credentials = $Credential }
    else { $wc.UseDefaultCredentials = $true }
    foreach($file in $files)
    {
        $DestUrl = "{0}{1}{2}" -f $Url.ToString().TrimEnd("/"), "/", $file.Name
        Write-Verbose "$( get-date -f s ): Uploading file: $_"
        $wc.UploadFile( $DestUrl , "PUT", $file.FullName )
        Write-Verbose "$( get-date -f s ): Upload completed"
    }       
}