#$User = Get-AdUser -Identity (Read-Host "Copiar do usuário (nome.sobrenome)") -Properties *

$firstname = Read-Host "Primeiro Nome"
$Lastname = Read-Host "Resto do Nome"
$NewUser = Read-Host "Username (nome.sobrenome)"
$NewName = "$firstname $lastname"
$Cargo = Read-Host "Cargo"
$Gestor = Read-Host "Gestor"

$NomeCompleto = Read-Host "Copiar do usuário"
$TermEmp = "(Name -like '$NomeCompleto')"
$User = Get-ADUser -Filter $TermEmp -Properties *
Write "Usuário selecionado: $User.SamAccountName"
$DN = $User.distinguishedName
$OUDN = ($User.DistinguishedName -split ",",2)[1]

$Password = Read-Host "Senha inicial"
$DNS_domain_name = "@meudominio.com.br"
$UserName = "$NewUser$DNS_domain_name"
New-ADUser -SamAccountName $NewUser -Name $NewName -GivenName $firstname -Surname $lastname -DisplayName $NewName -UserPrincipalName $UserName -Instance $DN -Company $User.Company -Department $User.Department -EmailAddress $UserName -Manager $User.Manager -ScriptPath $User.ScriptPath -Title $User.Title -Path $OUDN -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force)

$x = 0
$MembroDeGrupo = @("")
if($User.MemberOf.Count -gt 1){
    for($x ; $x -lt $User.MemberOf.Count; $x++){
        $Grupo = $User.MemberOf[$x] -split ",",2 
        $MembroDeGrupo += $Grupo[0] -replace 'CN=', ''
    }
}
foreach ($Grupo in $MembroDeGrupo) {
    $ADGrupo = Get-ADGroup -Filter "(Name -like '$Grupo')"
    $Grupo = $ADGrupo.SamAccountName
    Try{
        Add-ADGroupMember -Identity "$Grupo" -Members "$NewUser"
    }Catch{
        Write "$NewName não foi inserido no Grupo $Grupo pois o mesmo não foi encontrado"
    }
}
$Manager=(Get-ADUser -f {name -like $Gestor}).SamAccountName
Write "Gestor selecionado: $Manager"
Set-ADUser -Identity $NewUser -Manager $Manager -Title $Cargo -add @{"extensionattribute1"="$Gestor"}

Enable-ADAccount -Identity $NewUser
Get-ADUser -identity $NewUser
