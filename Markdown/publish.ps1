param(
    [string] $sourcePath,
    [uri] $targetUri
)
$ErrorActionPreference = "Stop"

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

# if the source path is relative, join with the script root
if(-not (split-path $sourcePath -IsAbsolute))
{
    $sourcePath = Join-Path $PSScriptRoot $sourcePath
}

UploadRecursive -targetUri $targetUri -path $sourcePath -filter "*.*"