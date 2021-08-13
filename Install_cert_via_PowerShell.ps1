# Instale certificados pelo PowerShell
# Altere o local do arquivo e a senha do certificado.

# Instalação do certificado na raiz da máquina
# Essa primeira etapa precisa de privilégios elevados
Get-Command -Module PKIClient;
Import-PfxCertificate -FilePath C:\Users\user\Downloads\Certificado.pfx -CertStoreLocation cert:\LocalMachine\Root -Exportable -Password (ConvertTo-SecureString -String 'senha' -Force -AsPlainText)

# Instalação do certificado no "Opções da internet" também via CLI
# Essa segunda etapa não precisa de privilégios elevados
certutil -user -p senha -importPFX C:\Users\user\Downloads\Certificado.pfx
