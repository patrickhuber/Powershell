function Get-ReleaseApiUri
{	
    [CmdletBinding()]  
	param(		
        [Parameter(Mandatory=$true)]
        [string] $scheme = 'http',
		[string] $hostName,		
        [int] $portNumber = 1000,
		[string] $apiVersion = '2.0',
        [hashtable] $queryParameters = @{},
        [string] $action
	)

    [System.UriBuilder] $uriBuilder = New-Object "System.UriBuilder"
    $uriBuilder.Scheme = $scheme
    $uriBuilder.Port = $portNumber
    $uriBuilder.Host = $hostName
    $uriBuilder.Path = "/account/releaseManagementService/_apis/releaseManagement/OrchestratorService/"
    $uriBuilder.Path += $action

    if($queryParameters -ne $null -and $queryParameters.Count -gt 0)
    {
        $uriBuilder.Query = [string]::Join("&", ($queryParameters.Keys | foreach{ "{0}={1}" -f $_, $queryString.Item($_) }))
    }
    return $uriBuilder.Uri
}