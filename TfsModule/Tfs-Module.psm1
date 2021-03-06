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
[accelerators]::Add('TfsTeamProjectCollectionFactory',"Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory, Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[accelerators]::Add('CatalogResourceTypes', "Microsoft.TeamFoundation.Framework.Common.CatalogResourceTypes, Microsoft.TeamFoundation.Common, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[accelerators]::Add('CatalogNode', "Microsoft.TeamFoundation.Framework.Client.CatalogNode, Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[accelerators]::Add('IIdentityManagementService', "Microsoft.TeamFoundation.Framework.Client.IIdentityManagementService, Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[accelerators]::Add('ICommonStructureService', "Microsoft.TeamFoundation.Server.ICommonStructureService, Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[accelerators]::Add('IdentityDescriptor', "Microsoft.TeamFoundation.Framework.Client.IdentityDescriptor, Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

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

<# Gets the TfsTeamProjectCollection object #>
function Get-TfsTeamProjectCollection
{
    [CmdletBinding(DefaultParametersetName="uri")]
    param(
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=0)]
        [uri]$uri,
        [Parameter(ParameterSetName="Uri", mandatory=$true, Position=1)]
        [string]$collectionName,
        [Parameter(ParameterSetName="CollectionUri", mandatory=$true, Position=0)]
        [string]$collectionUri)
    
    switch($PSCmdlet.ParameterSetName)
    {        
        "Uri" 
        {
            $collectionUri = Join-Uri $uri $collectionName
            break 
        }
    }
    return [TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($collectionUri);
}

<# Gets the TeamFoundationConfigurationServer object #>
function Get-TfsConfigurationServer
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
    $configurationServer = Get-TfsConfigurationServer -uri $uri
    $configurationServer.EnsureAuthenticated()
    $catalogNode = $configurationServer.CatalogNode
    
    # setup parameters to call qurey children method
    [Guid[]]$collectionFilter = @([CatalogResourceTypes]::ProjectCollection)
            
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

    switch($PSCmdlet.ParameterSetName)
    {        
        "Uri" 
        { 
            $teamProjectCollections = Get-TeamProjectCollections -uri $uri; 
            $teamProjectCollection = $teamProjectCollections | where { $_.Resource.DisplayName -eq $collectionName } | select -First 1            
            break
        }
        "TeamProjectCollection"
        {
            $teamProjectCollection = $teamProjectCollection
            break
        }
    }

    # setup parameters to call qurey children method
    $resourceTypes = [Microsoft.TeamFoundation.Framework.Common.CatalogResourceTypes]
    [Guid[]]$collectionFilter = @($resourceTypes::TeamProject)

    return $teamProjectCollection.QueryChildren($collectionFilter, $false, 'None')        
}

<# Get all top level groups for the tfs server #>
function Get-TeamFoundationConfigurationServerGroups
{
    [CmdletBinding(DefaultParametersetName="Uri")]    
    param(
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=0)]
        [uri]$uri)
    
    # create the team foundation server configuration 
    $teamFoundationConfigurationServer = Get-TfsConfigurationServer $uri

    # create the idenentity management service
    $identityManagementService = $teamFoundationConfigurationServer.GetService([IIdentityManagementService])

    return $identityManagementService.ListApplicationGroups($null, 'None')
}

<# Get all Groups for the Collection #>
function Get-TeamProjectCollectionGroups
{
    [CmdletBinding(DefaultParametersetName="Uri")]    
    param(
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=0)]
        [uri]$uri, 
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=1)]
        [string]$collectionName)

    # create the collection uri
    $collectionUri = Join-Uri $uri $collectionName

    # create the team project collection
    $teamProjectCollection = [TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($collectionUri)

    # create the identity management service from the team project collection
    $identityManagementService = $teamProjectCollection.GetService([IIdentityManagementService])

    # use the identity management service to return the list of project collection groups
    $teamProjectCollectionApplicationGroups = $identityManagementService.ListApplicationGroups($null, 'None')        
    
    $teamProjectCollectionGroupDescriptorArray = $teamProjectCollectionApplicationGroups |
        select -ExpandProperty Descriptor
        
    return $identityManagementService.ReadIdentities($teamProjectCollectionGroupDescriptorArray, 'Expanded', 'ExtendedProperties')
}

<# Get all Groups for the Project #>
function Get-TeamProjectGroups
{
    [CmdletBinding(DefaultParametersetName="Uri")]    
    param(
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=0)]
        [uri]$uri, 
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=1)]
        [string]$collectionName, 
        [Parameter(ParameterSetName="Uri", Mandatory=$true, Position=2)]
        [string]$projectName)

    # create the collection uri from the tfs uri     
    $collectionUri = Join-Uri $uri $collectionName

    # create the team project collection
    $teamProjectCollection = [TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($collectionUri)

    # create the identity management service from the team project collection
    $identityManagementService = $teamProjectCollection.GetService([IIdentityManagementService])

    # create the common structure service and get the project with the given project name
    $commonStructureService = $teamProjectCollection.GetService([ICommonStructureService])
    $project = $commonStructureService.GetProjectFromName($projectName)

    # use the identity management service to return the list of project groups
    $teamProjectApplicationGroups = $identityManagementService.ListApplicationGroups($project.Uri, 'None')

    $teamProjectGroupDescriptorArray = $teamProjectApplicationGroups |
        select -ExpandProperty Descriptor
        
    return $identityManagementService.ReadIdentities($teamProjectGroupDescriptorArray, 'Expanded', 'ExtendedProperties')
}

function Get-TeamProjectGroupMembership
{
    [CmdletBinding()]    
    param(        
        [Parameter(Mandatory=$true, Position=0)]
        [uri]$uri, 
        [Parameter(Mandatory=$true, Position=1)]
        [string]$collectionName,         
        [Parameter(Mandatory=$true, Position=2)]
        [string]$projectName,
        [Parameter(Mandatory=$true, Position=3)]
        [string]$groupName)
    
    # select the first matching team project group 
    $teamProjectGroup = Get-TeamProjectGroups $uri $collectionName $projectName | 
        where { $_.DisplayName -eq $groupName} |
        select -First 1
    
    $tfsTeamProjectCollection = Get-TfsTeamProjectCollection $uri $collectionName
    $identityService = $tfsTeamProjectCollection.GetService([IIdentityManagementService])
    
    return $identityService.ReadIdentities($teamProjectGroup.Members, 'Expanded', 'None')
}

function Get-TeamProjectCollectionGroupMembership
{
    [CmdletBinding()]    
    param(        
        [Parameter(Mandatory=$true, Position=0)]
        [uri]$uri, 
        [Parameter(Mandatory=$true, Position=1)]
        [string]$collectionName,
        [Parameter(Mandatory=$true, Position=3)]
        [string]$groupName)

    # select the first matching team project collection group
    $teamProjectCollectionGroup = Get-TeamProjectCollectionGroups $uri $collectionName | 
        where { $_.DisplayName -eq $groupName } | 
        select -First 1

    $tfsTeamProjectCollection = Get-TfsTeamProjectCollection -uri $uri -collectionName $collectionName
    $identityService = $tfsTeamProjectCollection.GetService([IIdentityManagementService])

    return $identityService.ReadIdentities($teamProjectCollectionGroup.Members, 'Expanded', 'None')
}

function Get-TeamFoundationConfgiurationServerGroupMembership
{
    [CmdletBinding()]    
    param(        
        [Parameter(Mandatory=$true, Position=0)]
        [uri]$uri,
        [Parameter(Mandatory=$true, Position=3)]
        [string]$groupName)
    
    $teamFoundationConfigurationServerGroup = Get-TeamFoundationConfigurationServerGroups -uri $uri |
        where { $_.DisplayName -eq $groupName } |
        select $_ -First 1
    
    # create the team foundation server configuration 
    $teamFoundationConfigurationServer = Get-TfsConfigurationServer $uri

    # get identity service from the team foundation configuration server#
    $identityService = $teamFoundationConfigurationServer.GetService([IIdentityManagementService])

    # formulate query using the member identity type and 
    $identityDescriptors = $teamProjectGroup.Members |         
        new-object [IdentityDescriptor] $_.IdentityType $_.Identifier

    return $identityService.ReadIdentities($identityDescriptors, 'Expanded', 'None')
}