$ErrorActionPreference = "Stop"
set-strictmode -version 3.0

Add-Type -AssemblyName @("System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35",
    "Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a",
    "Microsoft.TeamFoundation.Common, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a",
    "Microsoft.TeamFoundation, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

<# This is supposed to be available in v3, but for some reason I had to add it explicitly #>
$acceleratorsType = [type]::GetType("System.Management.Automation.TypeAccelerators, System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35", $true)
$acceleratorsType::Add("accelerators", $acceleratorsType)
[accelerators]::Add('TfsConfigurationServerFactory',"Microsoft.TeamFoundation.Client.TfsConfigurationServerFactory, Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[accelerators]::Add('CatalogResourceTypes', "Microsoft.TeamFoundation.Framework.Common.CatalogResourceTypes, Microsoft.TeamFoundation.Common, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[accelerators]::Add('CatalogNode', "Microsoft.TeamFoundation.Framework.Client.CatalogNode, Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

<# Gets the TeamFoundationConfigurationServer object #>
function Get-TeamFoundationConfigurationServer
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Uri]$uri)    
    return [TfsConfigurationServerFactory]::GetConfigurationServer($uri)
}

<# Gets the list of team foundation project collections from the given uri #>
function Get-TeamProjectCollections
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Uri]$uri)
    
    # get the configuraiton server 
    $configurationServer = Get-TeamFoundationConfigurationServer -uri $uri
    $configurationServer.EnsureAuthenticated()
    $catalogNode = $configurationServer.CatalogNode
    
    # setup parameters to call qurey children method
    [Guid[]]$collectionFilter = @($catalogResourceTypes::ProjectCollection)
            
    # execute the child query
    return $catalogNode.QueryChildren($collectionFilter, $false, 'None')
}

<# Gets the list of team projects from the given team project collection or (uri and collection name) #>
function Get-TeamProjects
{
    [CmdletBinding(DefaultParametersetName="TeamProjectCollection")]
    param(

        <# Uri Parameter Set #>
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=0)]
        [Uri]$uri,
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=1)]
        [string]$collectionName,

        <# Team Project Collection Parameter Set #>
        [Parameter(ParameterSetName="TeamProjectCollection", Mandatory=$true, Position=0)]
        [CatalogNode] $teamProjectCollection)

    $workingTeamProjectCollection = $null
    switch($PSCmdlet.ParameterSetName)
    {        
        "Uri" 
        { 
            $teamProjectCollections = Get-TeamProjectCollections -uri $uri; 
            $workingTeamProjectCollection = $teamProjectCollections | where { $_.Resource.DisplayName -eq $collectionName } | select -First 1            
            break
        }
        "TeamProjectCollection"
        {
            $workingTeamProjectCollection = $teamProjectCollection
            break
        }
    }

    # setup parameters to call qurey children method
    $resourceTypes = [Microsoft.TeamFoundation.Framework.Common.CatalogResourceTypes]
    [Guid[]]$collectionFilter = @($resourceTypes::TeamProject)

    return $workingTeamProjectCollection.QueryChildren($collectionFilter, $false, 'None')        
}