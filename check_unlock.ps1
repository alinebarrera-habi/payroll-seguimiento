# check_unlock.ps1 - baja la pagina PUBLICADA, le inyecta la contrasena en sessionStorage (como si el
# usuario ya la hubiera escrito) y la abre en Chrome headless para comprobar que WebCrypto la descifra
# y que el tablero real aparece (titulos <h2>, sin NaN). No sube nada. ASCII puro.
param(
  [string]$Url = 'https://alinebarrera-habi.github.io/payroll-seguimiento/',
  [string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'config.local.ps1')
$stamp = [Guid]::NewGuid().ToString('N').Substring(0,6)
$probe = Join-Path $env:TEMP "unlock_$stamp.html"; $udd = Join-Path $env:TEMP "udd_unlock_$stamp"; $dom = Join-Path $env:TEMP "dom_unlock_$stamp.html"
$page = (Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 60).Content
$inject = "<script>try{sessionStorage.setItem('payroll-pw'," + (ConvertTo-Json $PAYROLL_PASSWORD) + ");}catch(e){}</script>"
[IO.File]::WriteAllText($probe, $page.Replace('<script>', $inject + '<script>', [StringComparison]::Ordinal), (New-Object Text.UTF8Encoding($false)))
# .Replace reemplaza TODAS las ocurrencias; solo hay un <script> en el wrapper, asi que queda antes del BLOB.
$cargs = @('--headless=new','--disable-gpu','--no-sandbox','--virtual-time-budget=15000',"--user-data-dir=$udd",'--dump-dom',('file:///' + ($probe -replace '\\','/')))
& $Chrome @cargs 2>$null | Out-File -FilePath $dom -Encoding utf8
$t = [IO.File]::ReadAllText($dom)
$body = [regex]::Replace($t, '(?s)<script>.*?</script>', '')
"dom {0:n0} chars" -f $t.Length
"formulario de clave visible: {0}   (debe ser False si descifro)" -f ($t -match 'id="f"')
"titulos del tablero: " + (([regex]::Matches($body, '<h2>(.*?)</h2>') | ForEach-Object { $_.Groups[1].Value -replace '<[^>]+>','' } | Select-Object -First 4) -join ' | ')
"KPIs: " + (([regex]::Matches($body, '<h3>(.*?)</h3><div class="value[^"]*">(.*?)</div>') | ForEach-Object { ($_.Groups[1].Value -replace '<[^>]+>','') + '=' + ($_.Groups[2].Value -replace '<[^>]+>','') } | Select-Object -First 4) -join ' | ')
"NaN/undefined en pantalla: {0}/{1}" -f ([regex]::Matches($body,'NaN').Count), ([regex]::Matches($body,'undefined').Count)
Remove-Item -LiteralPath $probe,$dom -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $udd -Recurse -Force -ErrorAction SilentlyContinue
