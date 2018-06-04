Function Get-WeatherReport {
    <#
    .SYNOPSIS
        Gets the latest weather report.
    .DESCRIPTION
        Gets the latest weather report.
    .PARAMETER City
        Specifies the city you want the weather report for.
    .EXAMPLE
        Get-WeatherReport -City "New York"
    #>

    Param (
        [Parameter(Mandatory=$true)][String]$City
    )

    (curl http://wttr.in/$City -UserAgent "curl").Content
}