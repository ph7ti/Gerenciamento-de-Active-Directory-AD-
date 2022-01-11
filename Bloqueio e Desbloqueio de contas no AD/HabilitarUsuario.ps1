$logfile = ".\temp\Habilitar_output.txt"
$Data = Get-Date -Format "dd/MM/yyyy HH:mm"
$Nome = Read-Host 'Qual é o Primeiro Nome?'
$filter = "givenName -like ""$Nome"""
$User = Get-ADUser -Filter $filter -Properties *
$num = (Get-ADUser -Filter $filter -Properties *).Count
$opt = 1
if ((!$num) -and ($User -ne $null)){
    $num = 1
    $opt = 0
    Write-Host -NoNewline "`n"($x)"-"$User.Name " - Login:" $User.SamAccountName "- Habilitado:"$User.Enabled "`n"

}else{
For ($x = 0 ; $x -lt $num ; $x++) {
    Write-Host -NoNewline "`n"($x+1)"-"$User.Name[$x] " - Login:" $User.SamAccountName[$x] "- Habilitado:"$User.Enabled[$x] "`n"
    #Write-Host "Localização:" $User.DistinguishedName[$x]
    }
}
write "`n"
Write "######################################`n"
$selecao = Read-Host "Digite o número do colaborador a ser habilitado ou 0 para sair: "
write "`n"
$selecao = $selecao - 1
if(($selecao -lt $num) -and ($selecao -ge 0)){
    if($opt -eq 1){
        Enable-ADAccount -Identity $User.SamAccountName[$selecao]
        $output = Get-ADUser -identity $User.SamAccountName[$selecao] -Property Enabled | Where-Object {$_.Enabled -like “true”} | FT Name, Enabled -Autosize
    }else{
        Enable-ADAccount -Identity $User.SamAccountName
        $output = Get-ADUser -identity $User.SamAccountName -Property Enabled | Where-Object {$_.Enabled -like “true”} | FT Name, Enabled -Autosize
    }
    Write $Data $output | Out-File –Append -FilePath $logfile 
    gc $logfile -Tail 7
    Write "Acesso Restaurado com sucesso!"
}else{
    Write "`nNenhuma mudança efetuada"
}