$UserName = Read-Host "Username"
$DNS_domain_name = "@meudominio.com.br"
#$Password = "teste"
$Password = Read-Host "Password"
$UserName = "$UserName$DNS_domain_name"
Function Test-ADAuthentication {
    param($username,$password)
    
    (New-Object DirectoryServices.DirectoryEntry "",$username,$password).psbase.name -ne $null
}
$resultado = Test-ADAuthentication -username $UserName -password $password
Write "`nSenha confere: $resultado"