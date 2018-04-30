Import-Module ActiveDirectory
Import-CSV "bestandsnaam" | % {
    $UserName = $_.UserName
    $EmployeeID = $_.EmployeeID
    Set-ADUser $UserName -EmployeeID $EmployeeID
}
