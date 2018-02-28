Function Get-ArchiveUsage {
    <#
    .SYNOPSIS
        Get the archive usage information.
    .DESCRIPTION
        Queries MailboxStatistics to get the archive usage information from the selected user.
    .PARAMETER MailboxUPN
        Specifies the mailbox UserPrincipalName.
    .EXAMPLE
        Get-ArchiveUsage -MailboxUPN "a.user@somewhere.com"
    #> 
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)][String]$MailboxUPN
    )

    # Get the usage information for the users archive by quering MailboxStatistics.
    Try {
        $ArchiveUsage = Get-MailboxStatistics -Identity $MailboxUPN -Archive -ErrorAction Stop -WarningAction Stop | `
        Select-Object ItemCount,`
        @{Name="ArchiveTotalItemSizeMB"; expression={[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB))}}
    } Catch {
        # Couldn't get any usage information.
    }

    Return $ArchiveUsage
}

Function Get-MailboxUsage {
    <#
    .SYNOPSIS
        Get the mailbox usage information.
    .DESCRIPTION
        Queries MailboxStatistics to get the mailbox usage information from the selected user.
    .PARAMETER MailboxUPN
        Specifies the mailbox UserPrincipalName.
    .EXAMPLE
        Get-MailboxUsage -MailboxUPN "a.user@somewhere.com"
    #> 
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)][String]$MailboxUPN
    )

    # Get the usage information for the mailbox by querying MailboxStatistics.
    Try {
        $MailboxUsage = Get-MailboxStatistics -Identity $MailboxUPN -ErrorAction Stop -WarningAction Stop | `
        Select-Object LastLogonTime,ItemCount,`
        @{Name="TotalItemSizeMB"; expression={[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB))}}
    } Catch {
        # Couldn't get any usage information.
    }

    Return $MailboxUsage
}

Function Get-RecovFolderUsage {
    <#
    .SYNOPSIS
        Get the RecoverableFolder usage information.
    .DESCRIPTION
        Queries MailboxStatistics to get the RecoverableFolder usage information from the selected user.
    .PARAMETER MailboxUPN
        Specifies the mailbox UserPrincipalName.
    .EXAMPLE
        Get-RecovFolderUsage -MailboxUPN "a.user@somewhere.com"
    #>    
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory=$true)][String]$MailboxUPN
    )

    # Get the information for the recoverable folder by quering with MailboxFolderStatistics.
    Try {
        $RecovFolderUsage = Get-MailboxFolderStatistics -Identity $MailboxUPN -FolderScope RecoverableItems | `
        Where-Object {$_.Name -match "Recoverable Items"} | `
        Select-Object ItemsInFolderAndSubfolders,`
        @{Name="FolderAndSubfolderSizeMB"; expression={[math]::Round(($_.FolderAndSubfolderSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB))}}
    } Catch {
        # Couldn't get any usage information.
    }

    Return $RecovFolderUsage
}

Function Get-SharedMailboxUsers {
    <#
    .SYNOPSIS
        Get the authorized users for the mailbox.
    .DESCRIPTION
        Get the authorized users for the mailbox.
    .PARAMETER MailboxUPN
        Specifies the mailbox UserPrincipalName.
    .EXAMPLE
        Get-SharedMailboxUsers -MailboxUPN "a.user@somewhere.com"
    #>     
    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory=$true)][String]$MailboxUPN
    )

    # Get authorized users for the mailbox.
    Try {
        $SharedMailboxUsers = Get-Mailbox -Identity $MailboxUPN | Get-MailboxPermission | Where-Object {$_.User.ToString() -ne "NT AUTHORITYSELF" -and $_.IsInherited -eq $false} | Select-Object User
    } Catch {
        # No authorized users for the mailbox.
    }

    Return $SharedMailboxUsers
}