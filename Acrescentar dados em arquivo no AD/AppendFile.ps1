#Exemplo de script para acrescentar dados em arquivo CSV (No caso em questão o do Bloqueio e Desbloqueio de Férias)
#Edite conforme sua necessidade
#Define o local do arquivo a ser enviado
$LocationFolder = "$HOME\Documentos\Excel to CSV\"
#Identifica o arquivo que possui o formato .CSV 
$file = Get-ChildItem -Name $LocationFolder*.csv
#Arquivo destino, presente no servidor remoto (ele precisa existir inicialmente)
$remotefile = "Bloqueio de férias.csv"
#Origem + Arquivo
$pathfile = "$LocationFolder$file"
#Destino temporário do arquivo
$localpath = "C:\BloqueioDesbloqueioFerias\TEMP"
#Arquivo origem, contendo os dados novos
$origem = "C:\BloqueioDesbloqueioFerias\TEMP\$file"
#Arquivo destino, que receberá os dados novos
$destino = "C:\BloqueioDesbloqueioFerias\ArquivoCSV\$remotefile"
#Cria o arquivo de acesso, contendo o usuário e senha (criptografada)
#Variável contendo os dados da sessão remota
$UserPath = "$env:HOMEDRIVE$env:HOMEPATH"
$Cred = "$UserPath\Cred.xml"
#Verifica se o arquivo de autenticação existe, não existindo criará a mesma solicitando os dados de autenticação. Obs.: Usuário deve ter poderes administrativos sobre os recursos do AD
if (-not(Test-Path -Path $Cred -PathType Leaf)) {
    try {
        #Obtém um objeto de credencial com base em um nome de usuário e senha e exporta para um arquivo XML com dados criptografados. Esse cmdlet faz parte do módulo padrão Microsoft.PowerShell.Security
        Get-Credential | Export-Clixml -Path $Cred
        #O Export-Clixmlcmdlet criptografa objetos de credencial usando a API de Proteção de Dados do Windows. A criptografia garante que apenas sua conta de usuário naquele computador possa descriptografar o conteúdo do objeto de credencial. O arquivo exportado CLIXML não pode ser usado em um computador diferente ou por um usuário diferente.
    }catch {
        Write "Arquivo não existe nem foi criado.`nNão haverá conexão!`nEncerrando..."
        break
    }
}
$session = New-PSSession -computername SERVIDOR_AD01 -credential (Import-Clixml $Cred)
#Inicia o envio do arquivo para o host destino
Copy-Item -Path $pathfile -Destination $localpath -ToSession $session

#Envia o comando de adição dos dados do arquivo enviado para o destino. O comando deve ser enviado em bloco, para que as variáveis possam valer no host destino.
invoke-command $session -ScriptBlock {
Write "`n Arquivo original: `n"
#Leitura e exibição em tela do arquivo original
Get-Content -Path $Using:destino
#Leitura dos dados para a variável
$From = Get-Content -Path $Using:origem | Select-Object -Skip 1 | Select-Object -SkipLast 2
#Adição dos dados ao arquivo nov
Add-Content -Path $Using:destino -Value $From
Write "`n Arquivo Novo: `n"
#Leitura e exibição em tela do arquivo novo gerado
Get-Content -Path $Using:destino
}