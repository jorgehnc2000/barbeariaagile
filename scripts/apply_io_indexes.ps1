# Aplica a migration de índices I/O no projeto Supabase remoto.
# Senha: Dashboard → Project Settings → Database → Database password
#
# Uso (PowerShell):
#   $env:SUPABASE_DB_PASSWORD = "SUA_SENHA_DO_BANCO"
#   .\scripts\apply_io_indexes.ps1

$ErrorActionPreference = "Stop"

$projectRef = "rgrhalzcbhhydizlgztn"
$password = $env:SUPABASE_DB_PASSWORD

if ([string]::IsNullOrWhiteSpace($password)) {
  Write-Host "Informe a senha do Postgres do Supabase:" -ForegroundColor Yellow
  $secure = Read-Host -AsSecureString
  $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  )
}

if ([string]::IsNullOrWhiteSpace($password)) {
  throw "SUPABASE_DB_PASSWORD não informada."
}

$encoded = [uri]::EscapeDataString($password)
$dbUrl = "postgresql://postgres.${projectRef}:${encoded}@aws-1-us-east-2.pooler.supabase.com:5432/postgres"

Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  Write-Host "Aplicando migration 20260910120000_io_optimization_indexes.sql ..." -ForegroundColor Cyan
  npx --yes supabase@2.20.5 db push --db-url $dbUrl --include-all
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Write-Host "Migration aplicada com sucesso." -ForegroundColor Green
}
finally {
  Pop-Location
}
