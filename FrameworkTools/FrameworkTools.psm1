function Get-RegistryPath-For-FrameworkVersion
{
    param(
    [string] $frameworkVersion )
      
    $registryPath = ""  
    switch($frameworkVersion)
    {
        "4.5.1"
        {
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools"
        }
        "4.5"
        {
            $registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.0A\WinSDK-NetFx40Tools"
        }
        "4.0"
        {
            $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v7.0A\WinSDK-NetFx40Tools"
        }
		"3.5"
		{
		    $registryPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v6.0A\WinSDKNetFxTools"
		}
    }
    return $registryPath
}

function Get-Framework-Tools-Path(
    [string] $frameworkVersion)
{
    $sdkRegistryPath = Get-RegistryPath-For-FrameworkVersion -frameworkVersion $frameworkVersion
    $installationFolder = Get-ItemProperty -path "$sdkRegistryPath"`
	| Select-Object -ExpandProperty InstallationFolder
    return $installationFolder
}