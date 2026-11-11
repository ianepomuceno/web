# Publica la web en personal.us.es por SFTP.
#
# GitHub Actions compila la web y la guarda en la rama gh-pages. Este script
# descarga esa versión compilada y la sube al servidor de la US.
#
# Requisitos: estar conectada a la VPN de la US.
# Uso: doble clic en bin\deploy.cmd (o ejecutar: bin\deploy.cmd)

param(
  [string]$Server    = "personal.us.es",
  [string]$User      = "",               # tu usuario SFTP; si se deja vacío lo pregunta
  [string]$RemoteDir = "/inepomuceno",
  [string]$Branch    = "gh-pages"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent

function Fail($msg) { Write-Host "`nERROR: $msg" -ForegroundColor Red; exit 1 }

# 1. Comprobar que el servidor es accesible (VPN conectada)
Write-Host "Comprobando conexion con ${Server}:22 ..."
if (-not (Test-NetConnection $Server -Port 22 -InformationLevel Quiet -WarningAction SilentlyContinue)) {
  Fail "No se puede conectar a $Server por SFTP. Conecta la VPN de la US y vuelve a intentarlo."
}

# 2. Descargar la ultima version compilada
Write-Host "Descargando la web compilada desde GitHub ..."
git -C $repo fetch --quiet origin $Branch master
if ($LASTEXITCODE -ne 0) { Fail "git fetch ha fallado." }

$builtMsg  = git -C $repo log -1 --format="%s" "origin/$Branch"
$builtDate = git -C $repo log -1 --format="%cd" --date=format:"%d/%m/%Y %H:%M" "origin/$Branch"
$masterSha = git -C $repo rev-parse "origin/master"
$masterMsg = git -C $repo log -1 --format="%s" "origin/master"

Write-Host "Version compilada: $builtMsg ($builtDate)"
if ($builtMsg -notlike "*$masterSha*") {
  Write-Host "`nAVISO: la version compilada no corresponde al ultimo commit de master ('$masterMsg')." -ForegroundColor Yellow
  Write-Host "Puede que GitHub Actions aun este compilando o que haya fallado. Revisalo en la pestana Actions de GitHub." -ForegroundColor Yellow
  if ((Read-Host "Subir de todas formas la version compilada? (s/N)") -notmatch '^[sS]') { exit 1 }
}

$tmp = Join-Path $env:TEMP ("web-deploy-" + (Get-Date -Format "yyyyMMddHHmmss"))
$zip = "$tmp.zip"
git -C $repo archive --format=zip -o $zip "origin/$Branch"
if ($LASTEXITCODE -ne 0) { Fail "No se pudo extraer la rama $Branch." }
Expand-Archive -Path $zip -DestinationPath $tmp
Remove-Item $zip

try {
  # 3. Preparar las ordenes de SFTP (sube todo, sobrescribiendo lo que haya)
  $cmds = @("cd `"$RemoteDir`"")
  foreach ($item in Get-ChildItem -LiteralPath $tmp) {
    if ($item.Name.StartsWith(".")) { continue }   # .nojekyll, etc.
    if ($item.PSIsContainer) { $cmds += "put -r `"$($item.Name)`"" }
    else                     { $cmds += "put `"$($item.Name)`"" }
  }
  $cmds += "bye"
  $batch = Join-Path $tmp ".sftp-batch.txt"
  [IO.File]::WriteAllLines($batch, $cmds)   # UTF-8 sin BOM

  if (-not $User) { $User = Read-Host "Usuario SFTP" }

  # 4. Subir (pedira la contrasena)
  Write-Host "`nSubiendo a $User@${Server}:$RemoteDir (te pedira la contrasena) ..."
  Push-Location $tmp
  # BatchMode=no debe ir antes de -b para que se pueda escribir la contrasena
  sftp -o BatchMode=no -o StrictHostKeyChecking=accept-new -b $batch "$User@$Server"
  $code = $LASTEXITCODE
  Pop-Location
  if ($code -ne 0) { Fail "La subida por SFTP ha fallado (codigo $code)." }

  Write-Host "`nWeb publicada correctamente." -ForegroundColor Green
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
