#param ($User)
$User = Read-Host "Colaborador"
$UserFilter = "(Name -like '$User*')"

Get-ADUser -filter $UserFilter –Properties "DisplayName", "SamAccountName", "passwordlastset", "passwordneverexpires", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname", "SamAccountName", "passwordlastset", "passwordneverexpires" ,@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
