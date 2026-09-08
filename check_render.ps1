# check_render.ps1 - abre index.html (cifrado) en Chrome headless y confirma que carga el
# formulario de contrasena sin errores. No descifra nada. ASCII puro.
param([string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe')
$page = Join-Path $PSScriptRoot 'index.html'
$stamp = [Guid]::NewGuid().ToString('N').Substring(0,6)
$udd = Join-Path $env:TEMP ("udd_pay_$stamp"); $dom = Join-Path $env:TEMP ("dom_pay_$stamp.html")
$cargs = @('--headless=new','--disable-gpu','--no-sandbox','--virtual-time-budget=4000',"--user-data-dir=$udd",'--dump-dom',('file:///' + ($page -replace '\\','/')))
& $Chrome @cargs | Out-File -FilePath $dom -Encoding utf8
$t = [IO.File]::ReadAllText($dom)
"dom {0:n0} chars | formulario visible: {1} | titulo: {2}" -f $t.Length, ($t -match 'class="card" id="f"'), ([regex]::Match($t,'<title>(.*?)</title>').Groups[1].Value)
Remove-Item -LiteralPath $udd -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $dom -Force -ErrorAction SilentlyContinue
