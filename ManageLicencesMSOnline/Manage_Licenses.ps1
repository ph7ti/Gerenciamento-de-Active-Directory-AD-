param ($Email, $Acao)
#Licença básica de Office 365 para o usuário (Verifique suas licenças de acordo com sua conta em: https://docs.microsoft.com/en-us/microsoft-365/enterprise/view-account-license-and-service-details-with-microsoft-365-powershell?view=o365-worldwide )
$basic = "reseller-account:ENTERPRISEPACK"
#Diretório da credencial e log
$UserPath = "C:\GerenciarLicençasMS"
$logfile = "$UserPath\log\Licenças_output.log"
$cred = "$UserPath\Cred.xml"
$Data = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

if ((-not $Email)-or($Acao -gt 2)-or($Acao -lt 0)){
    write "`n>>> Parâmetro ou Opção Inválida!!! <<<`n`nOpções disponíveis:`n[0]: Remover Licenças`n[1]: Atribuir Licenças `n[ ]: Listar Opções (Help)`nExemplo de execução:`n.\Manage_Licenses.ps1 -Email fulano.beltrano@seudominio.com.br -Acao 1"
    break
}
#Verifica se o arquivo de autenticação existe, não existindo criará a mesma solicitando os dados de autenticação. Obs.: Usuário deve ter poderes administrativos sobre os recursos do azure. Caso usuário possua MFA ativo, o script não funcionará
if (-not(Test-Path -Path $cred -PathType Leaf)) {
    try {
        #Obtém um objeto de credencial com base em um nome de usuário e senha e exporta para um arquivo XML com dados criptografados. Esse cmdlet faz parte do módulo padrão Microsoft.PowerShell.Security
        Get-Credential | Export-Clixml -Path $cred
        #O Export-Clixmlcmdlet criptografa objetos de credencial usando a API de Proteção de Dados do Windows. A criptografia garante que apenas sua conta de usuário naquele computador possa descriptografar o conteúdo do objeto de credencial. O arquivo exportado CLIXML não pode ser usado em um computador diferente ou por um usuário diferente.
    }catch {
        Write "Arquivo não existe nem foi criado.`nNão haverá conexão!`nEncerrando..."
        break
    }
}
$cred = Import-CliXml -Path $cred
Try{
    #Conexão com a MS Online/Azure (Não é necessário fechar depois, como o da Exchange)
    Connect-MsolService -Credential $cred
    #Abre a conexão do Exchange
    Connect-ExchangeOnline -Credential $cred -ShowBanner:$false
}Catch{
    Write "Erro de conexão!!!`nEncerrando..."
    break
}
#Se executou o cógigo acima a conexão está Funcionando!
$stringarray= @("--------------------------- $Data - Log de alteração de licença ---------------------------")
#Verifica se o usuário está presente no azure e atribui a location BR, sem isso não é possível efetuar atribuir licenças na conta do usuário.
try{ Set-MsolUser -UserPrincipalName $Email -UsageLocation BR }
catch{ 
    $stringarray+= @("A conta $Usuario ainda não existe no Exchange/Azure")
    #Se a conta não existe o programa é finalizado
    break
}
try{ 
    #Verifica quais licenças o usuário possui
    $licenses = $(Get-MsolUser -UserPrincipalName $Email | Select Licenses).Licenses.AccountSKUid
    $Colab = $(Get-MsolUser -UserPrincipalName $Email | Select DisplayName).DisplayName
}catch{ $stringarray+= @("Erro ao obter informação das licenças de $Email") }
#Verifica se possui caixa de email
try{ 
    $typemail = $(Get-EXOMailbox -Identity  $Colab.DisplayName | Select RecipientTypeDetails).RecipientTypeDetails 
}catch{ 
    #Caso não possua uma conta de e-mail, define como falso seu tipo
    $typemail=$false
    $stringarray+= @("Erro ao obter informação do tipo de email de $Email")    
}
if (($Acao -eq 0) -and ($licenses)){
#Caso 0 -> Já possui licença(s), e TODAS serão removidas
    $stringarray+= @("# Ação: Remover Licenças #")
    #Converte caixa de email Regular e Shared (compartilhada)
    if ($typemail -eq "UserMailbox"){
        $stringarray+= @("Usuário $Colab possui caixa de email Regular")
        Get-EXOMailbox -Identity $Colab | set-mailbox -type “Shared”
        $stringarray+= @(" - Compartilhando caixa de email de $Colab ($Email)")
    }
    $stringarray+= @("Licenças do Usuário $Colab : $licenses")
    #remove todas as licenças encontradas
    foreach ($license in $licenses) {
        $stringarray+= @(" - Removendo Licença: $license")
        Try{
            Set-MsolUserLicense -UserPrincipalName $Email -RemoveLicenses $license
        }Catch{
            $stringarray+= @("#Atenção! Licença $license não foi removida do $Colab")
        }
    }
    #Verifica se ainda existe alguma licença
    if (-not $(Get-MsolUser -UserPrincipalName $Email | Select Licenses).Licenses.AccountSKUid){
        $stringarray+= @("Usuário $Colab não possui mais licenças")
    }
}elseif (($Acao -eq 1) -and (-not $licenses)){
#Caso 1 -> Sem licença
    $stringarray+= @("# Ação: Atribuir Licença Basica #","Usuário $Colab ainda não possui licenças"," - Atribuindo Licença $basic ao usuário $Colab")
    #Atribui a licença básica de Office
    Set-MsolUserLicense -UserPrincipalName $Email -AddLicenses $basic
    #Verifica se a licença foi mesmo atribuída 
    if ($(Get-MsolUser -UserPrincipalName $Email | Select Licenses).Licenses.AccountSKUid){
        $stringarray+= @("Licença de Pacote Office foi atribuida ao Usuário $Colab")
        #Verifica se a caixa é Shared (compartilhada) e altera para Regular
        if ($typemail -eq "SharedMailbox"){
            Get-EXOMailbox -Identity $Colab | set-mailbox -type “Regular”
            $stringarray+= @(" - Ajustando Caixa de email de $Colab ($Email) para Regular")
        }
    }
}elseif (($Acao -eq 1) -and ($licenses)){
#Caso já possua licenças, não faz nenhuma nova atribuição
    $stringarray+= @("# Ação: Atribuir Licença #","Usuário $Colab já possui licença(s): $licenses")
}elseif (-not $licenses){
#Caso não possua licença, apenas informa
    $stringarray+= @("Nenhuma licença encontrada para a conta de $Email")
}else{
    write "Nenhuma mudança efetuada"
}
Write "$stringarray`nFINISH!"
#Insere os dados no logfile
Write $stringarray | Out-File –Append -FilePath $logfile
#Fecha a conexão do Exchange
Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore -ErrorAction SilentlyContinue