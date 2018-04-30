Import-Module ActiveDirectory
Import-CSV "bestandsnaam" | ForEach-Object {
    $UserName = $_.UserName
    $EmployeeID = $_.EmployeeID
    Set-ADUser $UserName -EmployeeID $EmployeeID
}
