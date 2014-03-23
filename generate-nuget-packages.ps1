# stop on first error
$ErrorActionPreference = "Stop"

# type definitions
Add-Type @"
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.IO;
    using System.Reflection;

    /// <summary>
    ///    <see href="http://www.codeproject.com/Tips/353819/Get-all-Assembly-Information">source</see>
    /// </summary>
    public class AssemblyInfo
    {
        public AssemblyInfo(Assembly assembly)
        {
            if (assembly == null)
                throw new ArgumentNullException("assembly");
            this.assembly = assembly;
        }

        private readonly Assembly assembly;

        /// <summary>
        /// Gets the title property
        /// </summary>
        public string ProductTitle
        {
            get
            {
                return GetAttributeValue<AssemblyTitleAttribute>(a => a.Title, 
                       Path.GetFileNameWithoutExtension(assembly.CodeBase));
            }
        }

        /// <summary>
        /// Gets the application's version
        /// </summary>
        public string Version
        {
            get
            {
                string result = string.Empty;
                Version version = assembly.GetName().Version;
                if (version != null)
                    return version.ToString();
                else
                    return "1.0.0.0";
            }
        }

        /// <summary>
        /// Gets the description about the application.
        /// </summary>
        public string Description
        {
            get { return GetAttributeValue<AssemblyDescriptionAttribute>(a => a.Description); }
        }


        /// <summary>
        ///  Gets the product's full name.
        /// </summary>
        public string Product
        {
            get { return GetAttributeValue<AssemblyProductAttribute>(a => a.Product); }
        }

        /// <summary>
        /// Gets the copyright information for the product.
        /// </summary>
        public string Copyright
        {
            get { return GetAttributeValue<AssemblyCopyrightAttribute>(a => a.Copyright); }
        }

        /// <summary>
        /// Gets the company information for the product.
        /// </summary>
        public string Company
        {
            get { return GetAttributeValue<AssemblyCompanyAttribute>(a => a.Company); }
        }

        protected string GetAttributeValue<TAttr>(Func<TAttr, 
          string> resolveFunc, string defaultResult = null) where TAttr : Attribute
        {
            object[] attributes = assembly.GetCustomAttributes(typeof(TAttr), false);
            if (attributes.Length > 0)
                return resolveFunc((TAttr)attributes[0]);
            else
                return defaultResult;
        }
    } 
"@

# function definitions

# gets the framework name for the given assembly
function GetFrameworkName([System.Reflection.Assembly] $assembly)
{
    $frameworkVersion = $assembly.ImageRuntimeVersion
    if($frameworkVersion.StartsWith("v1.1"))
    {
        $frameworkVersion = "net11"
    }
    elseif($frameworkVersion.StartsWith("v2.0"))
    {
        $frameworkVersion = "net20"
    }
    elseif($frameworkVersion.StartsWith("v3.0"))
    {
        $frameworkVersion = "net30"
    }
    elseif($frameworkVersion.StartsWith("v3.5"))
    {
        $frameworkVersion = "net35"
    }
    elseif($frameworkVersion.StartsWith("v4.0"))
    {
        $frameworkVersion = "net40"
    }
    elseif($frameworkVersion.StartsWith("v4.5"))
    {
        $frameworkVersion = "net45"
    }
    return $frameworkVersion
}

function UpdateNuspecFileFromAssemblyInformation([string] $nuspecFile, [System.Reflection.Assembly] $assembly)
{    
    $assemblyInfo = New-Object AssemblyInfo($assembly)
    [xml] $nuspecXml = Get-Content $nuspecFile
    $nuspecXml.package.metadata.id = $assembly.GetName().Name
    $nuspecXml.package.metadata.version = $assemblyInfo.Version
    $nuspecXml.package.metadata.owners = $assemblyInfo.Company
    $nuspecXml.package.metadata.description = $assemblyInfo.Description
    $nuspecXml.Save($nuspecFile)
}

# main script body
$storageDir = $pwd
$nugetUrl = "https://www.nuget.org/nuget.exe"
$nuget = "$storageDir\nuget.exe"

# download nuget if it doesn't exist
if(-Not ([System.IO.File]::Exists($nuget)))
{
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($nugetUrl, $nuget)
}

# do a flat dll check
$assemblyEnumeration = [System.IO.Directory]::EnumerateFiles("$storageDir", "*.dll", [System.IO.SearchOption]::TopDirectoryOnly)
foreach($assemblyFile in $assemblyEnumeration)
{
    $assembly = [System.Reflection.Assembly]::LoadFrom($assemblyFile)
    $assemblyName = [System.IO.Path]::GetFileName($assemblyFile)

    $packageId = [System.IO.Path]::GetFileNameWithoutExtension($assemblyFile)
    $packageFolder = $assembly.GetName()
    $frameworkName = GetFrameworkName $assembly
    $packageRoot = "$storageDir\$packageid"
    $packageAssemblyPath = "$storageDir\$packageId\lib\$frameworkName"

    # generate package folder if it doesn't exist
    if(-not(Test-Path -Path $packageAssemblyPath))
    {
        New-Item -ItemType directory -Path $packageAssemblyPath
    }

    # copy the assembly into its proper folder
    Copy-Item $assemblyFile $packageAssemblyPath

    # generate nuspec file if it doesn't exist
    $packageNuspecFile = "$storageDir\$packageId\$packageid.nuspec"
    if(-not(Test-Path -Path $packageNuspecFile))
    {  
        # generate the nuspec file        
        (. $nuget spec "$packageAssemblyPath\$packageid")

        # the file will be generated with the following name
        $generatedNuspecFilePath = "$packageAssemblyPath\$packageid.nuspec"
             
        # on the first creation we need to update the nuspec xml with the 
        # assembly information
        UpdateNuspecFileFromAssemblyInformation $generatedNuspecFilePath $assembly

        # the nuspec file is generated next to the assembly
        # so move it to the package nuspec file location
        move-item "$generatedNuspecFilePath" $packageRoot
    }
}

# find all nuspec files
$nuspecEnumeration = [System.IO.Directory]::EnumerateFiles("$storageDir", "*.nuspec", [System.IO.SearchOption]::AllDirectories)

foreach($nuspecFile in $nuspecEnumeration)
{
    (. $nuget pack $nuspecFile)
    $nupkgFile = get-childitem "$storageDir\*.nupkg" | Select-Object -First 1
    move-item $nupkgFile "$storageDir\Feed" -force
}