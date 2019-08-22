<# Joins uri to a child path#>
function Join-Uri
{
    [CmdletBinding(DefaultParametersetName="Uri")]    
    param(
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=0)]
        [uri]$uri, 
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=1)]
        [string]$childPath)
    $combinedPath = [system.io.path]::Combine($uri.AbsoluteUri, $childPath.trim('/').trim('\'))
    $combinedPath = $combinedPath.Replace('\', '/').replace('/?', '?')
    return New-Object uri $combinedPath
}
