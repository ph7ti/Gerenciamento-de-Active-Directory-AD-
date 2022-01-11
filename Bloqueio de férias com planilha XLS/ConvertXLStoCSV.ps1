#SCRIPT PARA CONVERTER O ARQUIVO DE BLOQUEIO DE FÉRIAS DO FORMATO XLS PARA CSV
#O SCRIPT MANTEM APENAS OS DADOS NECESSÁRIOS PARA EFETUAR O BLOQUEIO, REMOVENDO TODO O RESTO

#DEFINA O LOCAL ONDE SERA ENCONTRADO O ARQUIVO
$LocationFolder = "C:\Excel to CSV\"
$TempFolder = "C:\Excel Repo\*"
#Remove os arquivos CSV antigos para não causar conflito
Get-ChildItem $LocationFolder*.csv | foreach { Remove-Item -Path $_.FullName }
#Opcional para debug, apenas copia de uma pasta o XLS, para que não remova o mesmo.
Copy-Item -Path $TempFolder -Destination $LocationFolder -Recurse
Start-Sleep -s 1
#Efetua a varredura na pasta informada buscando o arquivo
foreach($file in (Get-ChildItem $LocationFolder*.xls)) {
    #Atribui o nome com formato do arquivo de saídaz
    $newname = $file.FullName -replace '\.xls$', '.csv'
    #Inicia as funções CLI do Excel
    $objExcel = New-Object -ComObject Excel.Application
    $objExcel.Visible = $false
    #Indica o arquivo e planilha a ser avaliado
    $WorkBook = $objExcel.Workbooks.Open($file)
    $worksheet = $workbook.sheets.item("Sheet1")
    #Identifica o range de linhas a ser verificado
    $UsedRange = $worksheet.usedrange
    #Inicia a avaliação, pulando as 14 primeiras linhas, que contém dados não úteis ao bloqueio
    $Data = ForEach($Row in ($UsedRange.Rows|Select -skip 14)){
        #Cria um objeto com cabeçalho personalizado baseado em cada coluna verificada
        New-Object PSObject -Property @{
            'Nome' = $Row.Cells.Item(2).Value2
            'DataInicio' = $Row.Cells.Item(4).Value2
            'DataFim' = $Row.Cells.Item(5).Value2
            'DataRetorno' = $Row.Cells.Item(6).Value2
        }
    }
    #Exporta os dados obtidos em formato CSV, mantendo os cabeçalhos indicados
    $Data | Where{($_.'Nome') -ne ''} | Select 'Nome','DataInicio','DataFim','DataRetorno' | Export-Csv -NoTypeInformation -Path $newname
    $Data | Where{($_.'Nome') -ne ''} | Select 'Nome','DataInicio','DataFim','DataRetorno' | write
    #Finaliza o Excel CLI
    $objExcel.quit()
}
Start-Sleep -s 1
#Exclui o(s) arquivo(s) XLS que esta(ão) na pasta do CSV, mantendo apenas o último tipo
Get-ChildItem $LocationFolder*.xls | foreach { Remove-Item -Path $_.FullName }

#Agora é só colocar o arquivo gerado no AD, na pasta de verificação do Script "BloqueioDesbloqueioFerias.ps1"
exit