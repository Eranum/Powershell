$ScriptFile = $MyInvocation.MyCommand.Name
$ScriptLocation = Split-Path $MyInvocation.MyCommand.Path -Parent
$Path = "C:\Windows"

$TaskSequenceName = "$TSEnv:TaskSequenceName"
$TaskSequenceID = "$TSEnv:TaskSequenceID"
$BuildDate = Get-Date -Format yyyy-MM-dd

$WindowsVersion = (Get-ComputerInfo | Select-Object WindowsProductName).WindowsProductName
$WindowsVersionBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseID | Select-Object ReleaseID).ReleaseID
$WindowsVersion = $WindowsVersion + " " + $WindowsVersionBuild

$InstalledApplications = (Get-CimInstance win32_product | Select-Object -ExpandProperty Name | ForEach-Object { "- " + $_ } | Sort-Object | Out-String).Trim()


$Text = @"
==================================================
Build Informatie
 - MDT Task Sequence:    $TaskSequenceName
 - Build Date:           $BuildDate
 - Operating System:     $WindowsVersion

Installed applications
$InstalledApplications
==================================================

"@

$FilePath = $Path + "\" + $TaskSequenceID + "_" + $BuildDate + ".txt"
$Text | Out-File -FilePath $FilePath