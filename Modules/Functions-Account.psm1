Function Get-AccountStatus {
    <#
    .SYNOPSIS
        Checks if an account is enabled or disabled.
    .DESCRIPTION
        Checks if an account is enabled or disabled by querying the Active Directory by Alias.
        If the account isn't found, the Active Directory is searched by PrimarySmtpAddress.
    .PARAMETER MailboxAlias
        Specifies the users alias.
    .PARAMETER MailboxPSA
        Specifies the users PrimarySmtpAddress
    .PARAMETER MailboxDPN
        Specifies the users DisplayName
    .EXAMPLE
        Get-AccountStatus -MailboxAlias "a.user" -MailboxPSA "a.user@somewhere.com" -MailboxDPN "User, A"
    #>    
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory=$true)][String]$MailboxAlias,
        [Parameter(Mandatory=$true)][String]$MailboxPSA,
        [Parameter(Mandatory=$true)][String]$MailboxDPN
    )

    Try {
        $AccountStatus = Get-ADUser $MailboxAlias | Select-Object Enabled
        If ($AccountStatus.Enabled -eq $true) {
            $AccountEnabled = "True"
        } Else {
            $AccountEnabled = "False"
        }
    } Catch {
        # Could not determine the account status based on Alias, so try searhing the Active Directory by PrimarySmtpAddress.
        "Warning! Mailaddress doesn't match alias for: $MailboxDPN" | ForEach-Object -Process {Write-Warning -String $_ -WarningFile $LogFiles.WarningFile -LogFile $LogFiles.LogFile}
        Try {
            $AccountStatus = Get-ADUser -Filter * -Properties EmailAddress,Enabled | Where-Object {$_.EmailAddress -like $MailboxPSA} | Select-Object Enabled
            If ($AccountStatus.Enabled -eq $true) {
                $AccountEnabled = "True"
            } Else {
                $AccountEnabled = "False"
            }
        } Catch {
            # Could not determine the account status by Alias or PrimarySmtpAddress, so write and error to the log.
            "Error! Couldnt determine AD status for: $MailboxDPN" | ForEach-Object -Process {Write-Error -String $_ -ErrorFile $LogFiles.ErrorFile -LogFile $LogFiles.LogFile}
            $AccountEnabled = "Error"
        }
    }

    Return $AccountEnabled
}