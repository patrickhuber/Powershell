param(
    [string] $sourcePath,
    [uri] $targetUri
)
$ErrorActionPreference = "Stop"

. .\library.ps1

# resolve the source path
$sourcePath = Resolve-PathWithScriptRoot $sourcePath

UploadRecursive -targetUri $targetUri -path $sourcePath -filter "*.*"