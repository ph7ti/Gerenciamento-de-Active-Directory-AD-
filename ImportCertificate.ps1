# Script para importação de certificado via CLI
Get-Command -Module PKIClient;
Import-PfxCertificate -FilePath C:\Users\user\Downloads\Cert.pfx -CertStoreLocation cert:\LocalMachine\Root -Exportable -Password (ConvertTo-SecureString -String '12345678' -Force -AsPlainText)
