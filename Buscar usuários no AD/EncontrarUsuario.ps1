$Nome = Read-Host 'Qual é o Primeiro Nome?'
$filter = "givenName -like ""$Nome"""
$User = Get-ADUser -Filter $filter -Properties *
$num = (Get-ADUser -Filter $filter -Properties *).Count
$x = 0
if ((!$num) -and ($User -ne $null)){
    Write-Host -NoNewline "`n"($x+1)"-"$User.Name " - Login:" $User.SamAccountName "- Status:"$User.Enabled "`n"
    Write-Host "Localização:" $User.DistinguishedName

}else{
For ($x = 0 ; $x -lt $num ; $x++) {
    Write-Host -NoNewline "`n"($x+1)"-"$User.Name[$x] " - Login:" $User.SamAccountName[$x] "- Status:"$User.Enabled[$x] "`n"
    Write-Host "Localização:" $User.DistinguishedName[$x]
    }
}