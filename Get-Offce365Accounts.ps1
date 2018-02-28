<#
    .SYNOPSIS
        Get the Office 365 usage information for all specified domain accounts.
    .DESCRIPTION
        Get the Office 365 usage information for all specified domain accounts.
    .PARAMETER Domain
        Specifies the domain to query.
    .EXAMPLE
        Get-Office365Accounts.ps1 -Domain "domain.com"
#> 

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
    [System.Management.Automation.PSCredential][System.Management.Automation.CredentialAttribute()]$AdminCreds,
    [Parameter(Mandatory=$true)][String]$Domain
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Import modules
Import-Module ".\Modules\Functions-Account.psm1" -Force
Import-Module ".\Modules\Functions-Logging.psm1" -Force
Import-Module ".\Modules\Functions-Mailbox.psm1" -Force

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Logging Settings
$Logging = New-Log -RootPath "E:\Scripts\Get-Office365Accounts"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Connect to Exchange Online
$PSExchangeOnline = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" `
    -AllowRedirection -Authentication Basic -Credential $AdminCreds
Import-PSSession $PSExchangeOnline

# Create a DataTables to store the collected information
$dtAccountData = New-Object System.Data.DataTable "dtAccountData"
$dtAccountData.Columns.Add("DisplayName",[String]) | Out-Null
$dtAccountData.Columns.Add("UserPrincipalName",[String]) | Out-Null
$dtAccountData.Columns.Add("PrimarySmtpAddress",[String]) | Out-Null
$dtAccountData.Columns.Add("RecipientTypeDetails",[String]) | Out-Null
$dtAccountData.Columns.Add("AccountEnabled",[String]) | Out-Null
$dtAccountData.Columns.Add("WhenCreated",[String]) | Out-Null
$dtAccountData.Columns.Add("LastLogonTime",[String]) | Out-Null
$dtAccountData.Columns.Add("ItemCount",[String]) | Out-Null
$dtAccountData.Columns.Add("TotalItemSizeMB",[String]) | Out-Null
$dtAccountData.Columns.Add("ArchivePresent",[String]) | Out-Null
$dtAccountData.Columns.Add("ArchiveItemCount",[String]) | Out-Null
$dtAccountData.Columns.Add("ArchiveTotalItemSizeMB",[String]) | Out-Null
$dtAccountData.Columns.Add("RecoverableItemCount",[String]) | Out-Null
$dtAccountData.Columns.Add("RecoverableTotalItemSizeMB",[String]) | Out-Null
$dtAccountData.Columns.Add("SharedMailboxUsers",[String]) | Out-Null

$dtMailboxData = New-Object System.Data.DataTable "dtMailboxData"
$dtMailboxData.Columns.Add("DisplayName",[String]) | Out-Null
$dtMailboxData.Columns.Add("UserPrincipalName",[String]) | Out-Null
$dtMailboxData.Columns.Add("PrimarySmtpAddress",[String]) | Out-Null
$dtMailboxData.Columns.Add("Alias") | Out-Null
$dtMailboxData.Columns.Add("RecipientTypeDetails",[String]) | Out-Null
$dtMailboxData.Columns.Add("WhenCreated",[String]) | Out-Null
$dtMailboxData.Columns.Add("ArchiveDatabase",[String]) | Out-Null

# Grab all mailboxes from the specified domain
"Collecting all mailboxes in Exchange Online. This may take a few minutes." | ForEach-Object -Process {Write-Log $_ -LogFile $LogFiles.LogFile}
ForEach ($Mailbox in (Get-Mailbox -ResultSize Unlimited | Where-Object {$_.PrimarySmtpAddress -like "*$Domain"} | `
    Select-Object DisplayName,UserPrincipalName,PrimarySmtpAddress,Alias,RecipientTypeDetails,ArchiveDatabase,`
    @{Name="WhenCreated"; expression={$_.WhenCreated.ToString("yyyy-MM-dd")}} | `
    Sort-Object DisplayName)) {
    $NewRow = $dtMailboxData.NewRow()
    $NewRow.DisplayName = $Mailbox.DisplayName
    $NewRow.UserPrincipalName = $Mailbox.UserPrincipalName
    $NewRow.PrimarySmtpAddress = $Mailbox.PrimarySmtpAddress
    $NewRow.Alias = $Mailbox.Alias
    $NewRow.RecipientTypeDetails = $Mailbox.RecipientTypeDetails
    $NewRow.WhenCreated = $Mailbox.WhenCreated
    $NewRow.ArchiveDatabase = $Mailbox.ArchiveDatabase
    $dtMailboxData.Rows.Add($NewRow)
}    
"Collecting done. " + $dtMailboxData.Rows.Count + " mailboxes found." | ForEach-Object -Process {Write-Log $_ -LogFile $LogFiles.LogFile}

# Loop through each mailbox in the dtMailbox datatable in a ForEach loop.
ForEach ($Mailbox in $dtMailboxData) {
    "Processing: " + $Mailbox.DisplayName | ForEach-Object -Process {Write-Log $_ -LogFile $LogFiles.LogFile}
    # Reset variables so values from the previous loop are not imported.
    $AccountStatus = ""
    $MailboxUsage = ""
    $RecoverableFolderUsage = ""
    $SharedMailboxUsers = ""
    # Check if the mailbox is either an UserMailbox or a SharedMailbox, otherwise skip processing.
    If ($Mailbox.RecipientTypeDetails -eq "UserMailbox" -or $Mailbox.RecipientTypeDetails -eq "SharedMailbox") {
        # The mailbox is of the correct type.
    } Else {
        # The mailbox isn't of the correct type, so skip the rest of the ForEach loop as the mailbox should not be included in the report.
        Continue
    }

    # Check if the users is enabled or disabled in Active Directory
    $AccountStatus = Get-AccountStatus -MailboxAlias $Mailbox.Alias -MailboxPSA $Mailbox.PrimarySmtpAddress -MailboxDPN $Mailbox.DisplayName

    # Get the usage information for the users mailbox.
    $MailboxUsage = Get-MailboxUsage -MailboxUPN $Mailbox.UserPrincipalName

    # Check if the user has an archive, and if so get its usage information.
    If ($Mailbox.ArchiveDatabase -like "EUR*") {
        $ArchivePresent = "True"
        $ArchiveUsage = Get-ArchiveUsage -MailboxUPN $Mailbox.UserPrincipalName
    } Else {
        $ArchivePresent = "False"
    }
    
    # Get the usage information for the recoverable folder.
    $RecoverableFolderUsage = Get-RecovFolderUsage -MailboxUPN $Mailbox.UserPrincipalName

    # Get authorized users if it's an shared mailbox.
    If ($Mailbox.RecipientTypeDetails -eq "SharedMailbox") {
        $SharedMailboxUsers = Get-SharedMailboxUsers -MailboxUPN $Mailbox.UserPrincipalName
    } Else {
        $SharedMailboxUsers = ""
    }
    
    # Add all the collected information into the $dtAccountData datatable.
    $NewRow = $dtAccountData.NewRow()
    $NewRow.DisplayName = $Mailbox.DisplayName
    $NewRow.UserPrincipalName = $Mailbox.UserPrincipalName
    $NewRow.PrimarySmtpAddress = $Mailbox.PrimarySmtpAddress
    $NewRow.RecipientTypeDetails = $Mailbox.RecipientTypeDetails
    $NewRow.AccountEnabled = $AccountStatus
    $NewRow.WhenCreated = $Mailbox.WhenCreated
    $NewRow.LastLogonTime = $MailboxUsage.LastLogonTime
    $NewRow.ItemCount = $MailboxUsage.ItemCount
    $NewRow.TotalItemSizeMB = $MailboxUsage.TotalItemSizeMB
    $NewRow.ArchivePresent = $ArchivePresent
    $NewRow.ArchiveItemCount = $ArchiveUsage.ItemCount
    $NewRow.ArchiveTotalItemSizeMB = $ArchiveUsage.ArchiveTotalItemSizeMB
    $NewRow.RecoverableItemCount = $RecoverableFolderUsage.ItemsInFolderAndSubfolders
    $NewRow.RecoverableTotalItemSizeMB = $RecoverableFolderUsage.FolderAndSubfolderSizeMB
    $NewRow.SharedMailboxUsers = $SharedMailboxUsers
    $dtAccountData.Rows.Add($NewRow)

    "Processing done for: " + $Mailbox.DisplayName | ForEach-Object -Process {Write-Log $_ -LogFile $Logging.LogFile}
}

# Disconnect from Exchange Online
Remove-PSSession $PSExchangeOnline
$PSExchangeOnline = ""