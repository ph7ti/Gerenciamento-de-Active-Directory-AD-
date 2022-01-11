#SCRIPT 01 - PARA BLOQUEIO AUTOMATICO DE FERIAS
#NECESSITA SER EXECUTADO NO AD EM CONJUNTO COM O TASK SCHEDULER
#O ARQUIVO DE BLOQUEIO DEVE PASSAR PELA CONVERSÃO DE XLSX PARA CSV COM O SCRIPT "ConvertXLStoCSV.ps1"
#Função para limpar a acentuação da string
function get-sanitizedUTF8Input {
    Param(
        [String]$inputString
    )
    $replaceTable = @{"ß"="ss";"à"="a";"á"="a";"â"="a";"ã"="a";"ä"="a";"å"="a";"æ"="ae";"ç"="c";"è"="e";"é"="e";"ê"="e";"ë"="e";"ì"="i";"í"="i";"î"="i";"ï"="i";"ð"="d";"ñ"="n";"ò"="o";"ó"="o";"ô"="o";"õ"="o";"ö"="o";"ø"="o";"ù"="u";"ú"="u";"û"="u";"ü"="u";"ý"="y";"þ"="p";"ÿ"="y"}
    foreach($key in $replaceTable.Keys) {
        $inputString = $inputString -Replace($key,$replaceTable.$key)
    }
    return $inputString
}
#Indique o local do arquivo
$file = "C:\BloqueioDesbloqueioFerias\ArquivoCSV\*.csv"
$output = "C:\BloqueioDesbloqueioFerias\TEMP\output.txt"
#Processo de remoção do conjunto de vírgulas (,,,) que permanecem no fim do documento após a conversão para CSV
Set-Content -Path $file -Value (get-content -Path $file | Select-String -Pattern ',,,' -NotMatch)
#Captura a data do dia atual
$today = Get-Date -Format "dd/MM/yyyy"
Write "`n############################`nLog de execução - $today `n############################`n" | Out-File –Append -FilePath $output
#Indica o local do arquivo a ser selecionado
$csv = Import-Csv -Path $file
#Inicia a varredura no arquivo
foreach($item in $csv) {
    #Seleciona os dados baseado no cabeçalho do CSV
    $DataInicio = $($item.DataInicio)
    $DataFim = $($item.DataFim)
    $DataRetorno = $($item.DataRetorno)
    $nome = $($item.Nome)
    #Efetua a remoção de acentos
    $nome = get-sanitizedUTF8Input -inputString $nome
    #Substitui espaços por asteriscos
    $nome = $nome -replace ' ', '*'
    #Indica o método de filtro do AD
    $TermEmp = "(Name -like '$nome')"
    #Captura o SamAccount do colaborador com base no nome
    $Emp = Get-ADUser -Filter $TermEmp -Properties *
    $login = $Emp.SamAccountName
    #Formata a data no padrão MS
    $DataInicio = Get-Date -Format "dd/MM/yyyy" $DataInicio
    $DataRetorno = Get-Date -Format "dd/MM/yyyy" $DataRetorno
    #Verifica se a data de bloqueio é a mesma da data atual
    if($today -eq $DataInicio) {
        write "Bloquear: - $login - $nome `nFérias: $DataInicio " | Out-File –Append -FilePath $output 
        #Efetua o bloqueio do colaborador
        Disable-ADAccount -Identity $login
        $User = Get-ADUser -Filter $TermEmp -Properties *
        Write "Habilitado:"$User.Enabled "`n" | Out-File –Append -FilePath $output 
    }
    #Verifica se a data de desbloqueio é a mesma da data atual
    if($today -eq $DataRetorno) {
        write "Desbloquear: - $login - $nome `nRetorno: $DataRetorno " | Out-File –Append -FilePath $output 
        #Efetua o desbloqueio do colaborador
        Enable-ADAccount -Identity  $login
        $User = Get-ADUser -Filter $TermEmp -Properties *
        Write "Habilitado:"$User.Enabled "`n" | Out-File –Append -FilePath $output 
    }
}
Write "`n####################`nFim da execução`n####################" | Out-File –Append -FilePath $output
#It's All Folks!
exit
