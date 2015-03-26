function Invoke-InitiateReleaseFromBuild
{
	param(
        [Parameter(Mandatory=$true)]
        [string] $scheme = 'http',
		[string] $hostName,		
        [int] $portNumber = 1000,               
		[string] $apiVersion = '2.0',
        [Parameter(Mandatory=$true)]
		[string] $tfsServerUrl,
        [Parameter(Mandatory=$true)]
		[string] $teamProject,
        [Parameter(Mandatory=$true)]
		[string] $buildDefinition,
        [Parameter(Mandatory=$true)]
		[string] $buildNumber,
        [Parameter(Mandatory=$true)]
		[string] $targetStage
	)
    $queryParameters = @{ "releaseTemplateName" = $releaseTemplateName}
	$uri = Get-ReleaseApiUri `
        -scheme $scheme `
        -hostName $hostName `
        -portNumber $portNumber `
        -apiVersion $apiVersion `
        -action "AbandonRelease" `
        -queryParameters $queryParameters

    Invoke-WebRequest -Uri $uri -Method Get
}