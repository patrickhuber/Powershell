# Load all script files recursively into this module
# http://www.kmerwin.com/?p=174
gci $psscriptroot\*.ps1 -exclude ChocolateyInstall.ps1 -Recurse | % {. $_.FullName }
Export-ModuleMember -Alias * -Function * -Cmdlet *