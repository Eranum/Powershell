Function New-Log {
    <#
    .SYNOPSIS
        Creates a new Generic, Warning and Error log file.
    .DESCRIPTION
        Creates a new subfolder in a provided root folder based on the current date and
        time. Within this subfolder three log files are created for generic, warning and
        error output from a script.
    .PARAMETER RootPath
        Specifies the root folder for the logfiles.
    .EXAMPLE
        New-Log -RootPath "D:\Logging"
    #>

    Param (
        [Parameter(Mandatory=$true)][String]$RootPath
    )

    $LoggingDate = Get-Date -Format yyyyMMdd-HHmmss
    $LogFile = "$RootPath\$LoggingDate\_Generic.log"
    $WarningFile = "$RootPath\$LoggingDate\_Warning.log"
    $ErrorFile = "$RootPath\$LoggingDate\_error.log"

    New-Item -Path "$LogFile" -ItemType File -Force | Out-Null
    New-Item -Path "$WarningFile" -ItemType File -Force | Out-Null
    New-Item -Path "$ErrorFile" -ItemType File -Force | Out-Null

    $Global:LogFiles = "" | Select-Object -Property LogFile,WarningFile,ErrorFile
    $LogFiles.LogFile = $LogFile
    $LogFiles.WarningFile = $WarningFile
    $LogFiles.ErrorFile = $ErrorFile

    Return $LogFiles
}

Function Write-Log {
    <#
    .SYNOPSIS
        Writes a new line to the Generic log file.
    .DESCRIPTION
        Writes a new line to the Generic log file
    .PARAMETER LogFile
        Specifies the path to the Generic logfile.
    .PARAMETER String
        Specifies to text to be written to the file.
    .EXAMPLE
        Write-Log -LogFile $LogFiles.LogFile -String "Lorem Ipsum"
    #>

    Param (
        [Parameter(Mandatory=$true)][String]$LogFile,
        [Parameter(Mandatory=$true)][String]$String
    )

    $CurrentDate = Get-Date
    Write-Host -ForegroundColor White "$CurrentDate - $String"
    "$CurrentDate - $String" | Out-File -FilePath $LogFile -Append
}

Function Write-Warning {
    <#
    .SYNOPSIS
        Writes a new line to the Warning and Generic log file.
    .DESCRIPTION
        Writes a new line to the Warning and Generic log file
    .PARAMETER WarningFile
        Specifies the path to the Warning logfile.
    .PARAMETER LogFile
        Specifies the path to the Generic logfile.
    .PARAMETER String
        Specifies to text to be written to the file.
    .EXAMPLE
        Write-Warning -WarningFile $LogFiles.WarningFile -LogFile $LogFiles.LogFile -String "Lorem Ipsum"
    #>

    Param (
        [Parameter(Mandatory=$true)][String]$WarningFile,
        [Parameter(Mandatory=$true)][String]$LogFile,
        [Parameter(Mandatory=$true)][String]$String
    )

    $CurrentDate = Get-Date
    Write-Host -ForegroundColor Yellow "$CurrentDate - $String"
    "$CurrentDate - $String" | Out-File -FilePath $WarningFile -Append
    "$CurrentDate - $String" | Out-File -FilePath $LogFile -Append
}

Function Write-Error {
    <#
    .SYNOPSIS
        Writes a new line to the Error and Generic log file.
    .DESCRIPTION
        Writes a new line to the Error and Generic log file
    .PARAMETER ErrorFile
        Specifies the path to the Error logfile.
    .PARAMETER LogFile
        Specifies the path to the Generic logfile.
    .PARAMETER String
        Specifies to text to be written to the file.
    .EXAMPLE
        Write-Warning -ErrorFile $LogFiles.ErrorFile -LogFile $LogFiles.LogFile -String "Lorem Ipsum"
    #>

    Param (
        [Parameter(Mandatory=$true)][String]$ErrorFile,
        [Parameter(Mandatory=$true)][String]$LogFile,
        [Parameter(Mandatory=$true)][String]$String
    )

    $CurrentDate = Get-Date
    Write-Host -ForegroundColor Red "$CurrentDate - $String"
    "$CurrentDate - $String" | Out-File -FilePath $ErrorFile -Append
    "$CurrentDate - $String" | Out-File -FilePath $LogFile -Append
}