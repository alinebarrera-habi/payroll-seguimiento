# publish.ps1 - cifra el Tablero de Seguimiento de Payroll y lo publica en GitHub Pages.
#
#   Fuente (sin cifrar, NUNCA se sube): C:\Users\alinebarrera_habi\Desktop\Tableros\Tablero_Payroll_Habi.html
#   Salida (cifrada, lo unico que va al repo): .\index.html
#   Contrasena: en .\config.local.ps1 ($PAYROLL_PASSWORD) - archivo gitignored.
#
# Uso:  powershell -NoProfile -ExecutionPolicy Bypass -File publish.ps1            # cifra + commit + push
#       powershell -NoProfile -ExecutionPolicy Bypass -File publish.ps1 -NoPush    # solo cifra y commitea
# ASCII puro.
param(
  [string]$Source = 'C:\Users\alinebarrera_habi\Desktop\Tableros\Tablero_Payroll_Habi.html',
  [switch]$NoPush,
  [string]$Mensaje = ''
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$repo = $PSScriptRoot
$cfg = Join-Path $repo 'config.local.ps1'
if (-not (Test-Path $cfg)) { throw "Falta $cfg con `$PAYROLL_PASSWORD = '...'" }
. $cfg
if (-not $PAYROLL_PASSWORD -or $PAYROLL_PASSWORD.Length -lt 12) { throw 'PAYROLL_PASSWORD vacia o muy corta (min 12)' }
if (-not (Test-Path $Source)) { throw "No existe la fuente: $Source" }

$out = Join-Path $repo 'index.html'
"-> cifrando {0} ({1:n1} MB)" -f (Split-Path $Source -Leaf), ((Get-Item $Source).Length / 1MB)
python (Join-Path $repo 'encrypt_page.py') $Source $out $PAYROLL_PASSWORD
if ($LASTEXITCODE -ne 0) { throw 'fallo el cifrado' }

# prueba de ida y vuelta: que la contrasena de verdad abra lo que acabamos de escribir
$chk = @"
import sys, json, base64, re
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
page = open(sys.argv[1], encoding='utf-8').read()
blob = json.loads(re.search(r'const BLOB = (\{.*?\});', page).group(1))
b = lambda s: base64.b64decode(s)
key = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=b(blob['salt']), iterations=blob['iter']).derive(sys.argv[2].encode())
html = AESGCM(key).decrypt(b(blob['nonce']), b(blob['ct']), None)
src = open(sys.argv[3], 'rb').read()   # bytes: en modo texto Python normaliza los \r\n y la comparacion falla
print('roundtrip OK (%d bytes)' % len(html) if html == src else 'ROUNDTRIP MISMATCH'); sys.exit(0 if html == src else 1)
"@
$chkFile = Join-Path $env:TEMP 'payroll_chk.py'
[IO.File]::WriteAllText($chkFile, $chk, (New-Object Text.UTF8Encoding($false)))
python $chkFile $out $PAYROLL_PASSWORD $Source
if ($LASTEXITCODE -ne 0) { throw 'la pagina cifrada NO abre con la contrasena configurada' }
Remove-Item $chkFile -Force -ErrorAction SilentlyContinue

# corte del tablero (ultimo mes del roster) para el mensaje de commit
$corte = ''
$m = [regex]::Match((Get-Content $Source -Raw -Encoding UTF8), 'const ROSTER=\{m:\[(.*?)\]')
if ($m.Success) { $corte = ((($m.Groups[1].Value -split ',') | Select-Object -Last 1) -replace '"','') }
if ($Mensaje -eq '') { $Mensaje = "Publicar tablero de seguimiento (cifrado) - corte $corte - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }

git -C $repo add index.html
$st = git -C $repo status --porcelain index.html
if (-not $st) { "-> nada que publicar (index.html identico)"; exit 0 }
git -C $repo commit -q -m $Mensaje
"-> commit: $Mensaje"
if ($NoPush) { "-> sin push (-NoPush)"; exit 0 }
git -C $repo push origin main
""
"OK publicado. Link: https://alinebarrera-habi.github.io/payroll-seguimiento/"
"La contrasena esta en config.local.ps1 (no se sube)."
