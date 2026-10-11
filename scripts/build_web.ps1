$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$envPath = Join-Path $repoRoot '.env'
if (-not (Test-Path -LiteralPath $envPath)) {
  throw 'Missing .env. Copy .env.example to .env and set API_BASE_URL.'
}

$line = Get-Content -LiteralPath $envPath |
  Where-Object { $_ -match '^\s*API_BASE_URL\s*=' } |
  Select-Object -Last 1
if (-not $line) { throw 'API_BASE_URL is missing from .env.' }
$apiBaseUrl = ($line -replace '^\s*API_BASE_URL\s*=\s*', '').Trim().Trim('"').Trim("'")
if (-not $apiBaseUrl) { throw 'API_BASE_URL is empty in .env.' }

Push-Location $repoRoot
try {
  flutter build web --release "--dart-define=API_BASE_URL=$apiBaseUrl"
  if ($LASTEXITCODE -ne 0) { throw "Flutter build failed with exit code $LASTEXITCODE." }
} finally {
  Pop-Location
}
