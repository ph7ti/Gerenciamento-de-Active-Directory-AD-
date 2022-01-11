param ($Colaborador, $Usuario, $Cargo, $Gestor, $CopiarDe, $Password)
#Tenta fazer a checagem se o colaborador já existe, caso positivo, encerra a aplicação, do contrário prossegue na criação de usuário
if ((-not $Colaborador)-or(-not $Usuario)-or(-not $Cargo)-or(-not $Gestor)-or(-not $CopiarDe)-or(-not $Password)){
    write "`n>>> Parametros não foram inseridos de forma correta!!! <<<`n`nExemplo de execução:`n.\CopiarUsuario.ps1 -Colaborador 'Dino da Silva Sauro' -Usuario dino.sauro@seudominio.com.br -Cargo 'Engenheiro de demolição' -Gestor 'Bradley P. Richfield' -CopiarDe 'Roy Hess' -Password 'Na0e@mama&'"
    break
}
try {
    Get-ADUser -Identity $Usuario
    Exit "Usuario já existe"
    break
}Catch{
    #Define o arquivo de LOG
    $LogFile = "C:\log\CreateUsers.log"
    #Coleta a data/hora atual
    $today = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    #Inicia os dados de LOG
    $stringarray= @("############################","Log de execução - $today ","############################","Nome completo do colaborador: $Colaborador")
    #Efetua a splitagem e limpeza de dados
    $temp = $Colaborador -split (" "[0])
    [String]$firstname = $temp[0]
    [String]$lastname = $Colaborador -split ("$firstname ")
    #Insere dados no Log
    $stringarray+= @("Username (nome.sobrenome): $firstname$lastname")
    $stringarray+= @("Cargo: $Cargo")
    #Coleta os dados do Gestor
    $TermEmp = "(Name -like '$Gestor')"
    $UserGestor = Get-ADUser -Filter $TermEmp -Properties *
    $GestorSAN= $UserGestor.SamAccountName
    $stringarray+= @("Gestor: $GestorSAN")
    #Coleta os dados do perfil de colaborador espelho
    $TermEmp = "(Name -like '$CopiarDe')"
    $User = Get-ADUser -Filter $TermEmp -Properties *
    $CopiarDeSAN = $User.SamAccountName
    $stringarray+= @("Copiar do Usuário: $CopiarDeSAN")
    #Especifica o caminho completo para o objeto que será copiado (perfil espelho)
    $DN = $User.distinguishedName
    #Especifica a unidade organizacional (UO) para o novo usuário com base no perfil espelho
    $OUDN = ($User.DistinguishedName -split ",",2)[1]
    #Acrescenta o seu domínio
    $DNS_domain_name = "@seudominio.com.br"
    $UserNameFull = "$Usuario$DNS_domain_name"
    #Efetua a criação do usuário, com base nos valores informados e coletados (gestor e perfil espelho)
    New-ADUser -SamAccountName $Usuario -Name $Colaborador -GivenName $firstname -Surname $lastname -DisplayName $Colaborador -UserPrincipalName $UserNameFull -Instance $DN -Company $User.Company -Department $User.Department -EmailAddress $UserNameFull -Manager $User.Manager -ScriptPath $User.ScriptPath -Title $User.Title -Path $OUDN -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force)
    
    #Atribui os grupos ao novo usuário com base no perfil espelho
    $MembroDeGrupo = @("")
    if($User.MemberOf.Count -gt 1){
        $x = 0
        for($x ; $x -lt $User.MemberOf.Count; $x++){
            $Grupo = $User.MemberOf[$x] -split ",",2 
            $MembroDeGrupo += $Grupo[0] -replace 'CN=', ''
        }
    }
    foreach ($Grupo in ($MembroDeGrupo | select -skip 1)) {
        $ADGrupo = Get-ADGroup -Filter "(Name -like '$Grupo')"
        $Grupo = $ADGrupo.SamAccountName
        Try{
            Add-ADGroupMember -Identity "$Grupo" -Members "$Usuario"
            $stringarray+= @(" - $Colaborador foi inserido no Grupo $Grupo")
        }Catch{
            Write "$Colaborador não foi inserido no Grupo $Grupo pois o mesmo não foi encontrado"
        }
    }
    #Atribui o gestor ao novo usuário
    Try{
        $Manager=(Get-ADUser -f {name -like $Gestor}).SamAccountName
        $stringarray+= @("Gestor selecionado: $Manager")
        Set-ADUser -Identity $Usuario -Manager $Manager -Title $Cargo -add @{"extensionattribute1"="$Gestor"}
        Enable-ADAccount -Identity $Usuario
        Add-Content -Path $LogFile (Get-ADUser -identity $Usuario -Properties *)
        $stringarray+= @("Conta criada conforme solicitado!")
    }Catch{
        $stringarray+= @("Gestor não foi atribuído")
        $stringarray+= @("Erro na criação da Conta!")
    }
    Write "$stringarray`nFINISH!"
    #Grava os dados no arquivo de LOG
    Write $stringarray | Out-File –Append -FilePath $LogFile
}
