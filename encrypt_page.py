#!/usr/bin/env python3
"""Cifra un HTML autocontenido detras de una contrasena (AES-256-GCM + PBKDF2, 200k iteraciones).

Adaptado de blt-dashboard/scripts/encrypt_dashboard.py para el Tablero de Seguimiento de Payroll:
titulo propio y llave de sessionStorage propia ('payroll-pw'), para que no comparta sesion con el BLT.

Uso:
  python encrypt_page.py <entrada.html> <salida.html> <contrasena>

El repo que hospeda la salida es PUBLICO (GitHub Pages) -> lo unico que protege el contenido es la
contrasena. Sin ella, la pagina es un bloque base64 ilegible.
"""
import sys, os, base64, json
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

ITERATIONS = 200_000


def main():
    inp, outp, password = sys.argv[1], sys.argv[2], sys.argv[3]
    html = open(inp, "rb").read()

    salt = os.urandom(16)
    nonce = os.urandom(12)
    kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt, iterations=ITERATIONS)
    key = kdf.derive(password.encode("utf-8"))
    ct = AESGCM(key).encrypt(nonce, html, None)

    blob = {
        "salt": base64.b64encode(salt).decode(),
        "nonce": base64.b64encode(nonce).decode(),
        "ct": base64.b64encode(ct).decode(),
        "iter": ITERATIONS,
    }
    page = WRAPPER.replace("__BLOB__", json.dumps(blob))
    open(outp, "w", encoding="utf-8").write(page)
    print(f"wrote {outp}  ({len(page):,} bytes)")


WRAPPER = """<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>Habi &middot; Payroll &middot; Seguimiento</title>
<style>
  body{margin:0;font:15px/1.5 -apple-system,system-ui,Helvetica,Arial,sans-serif;
       background:#f7f8fa;color:#1e1b4b;display:flex;min-height:100vh;align-items:center;justify-content:center}
  .card{background:#fff;border:1px solid #e9d5ff;border-radius:12px;padding:28px 30px;max-width:360px;
        box-shadow:0 4px 20px rgba(76,29,149,.08);text-align:center}
  h1{font-size:18px;margin:0 0 4px;color:#4C1D95}
  p{font-size:13px;color:#6b7280;margin:0 0 18px}
  input{width:100%;padding:11px 12px;font-size:14px;border:1px solid #d8b4fe;border-radius:8px;box-sizing:border-box}
  button{margin-top:12px;width:100%;padding:11px;font-size:14px;font-weight:600;color:#fff;
         background:#6d28d9;border:none;border-radius:8px;cursor:pointer}
  button:hover{background:#5b21b6}
  .err{color:#b91c1c;font-size:12px;margin-top:10px;min-height:16px}
  .card-hidden{display:none}
</style></head>
<body>
  <form class="card card-hidden" id="f">
    <h1>Habi &middot; Payroll &middot; Seguimiento</h1>
    <p>Ingresa la contrase&ntilde;a para ver el tablero.</p>
    <input type="password" id="pw" autocomplete="current-password" autofocus placeholder="Contrase&ntilde;a">
    <button type="submit">Entrar</button>
    <div class="err" id="err"></div>
  </form>
<script>
const BLOB = __BLOB__;
const SS_KEY = 'payroll-pw';
const b64 = s => Uint8Array.from(atob(s), c => c.charCodeAt(0));

async function tryDecrypt(pw) {
  const enc = new TextEncoder();
  const baseKey = await crypto.subtle.importKey('raw', enc.encode(pw), 'PBKDF2', false, ['deriveKey']);
  const key = await crypto.subtle.deriveKey(
    {name:'PBKDF2', salt:b64(BLOB.salt), iterations:BLOB.iter, hash:'SHA-256'},
    baseKey, {name:'AES-GCM', length:256}, false, ['decrypt']);
  const plain = await crypto.subtle.decrypt({name:'AES-GCM', iv:b64(BLOB.nonce)}, key, b64(BLOB.ct));
  return new TextDecoder().decode(plain);
}

function reveal(html) {
  document.open(); document.write(html); document.close();
}

(async () => {
  const cached = (function(){ try { return sessionStorage.getItem(SS_KEY); } catch(_) { return null; } })();
  if (cached) {
    try { reveal(await tryDecrypt(cached)); return; }
    catch(_) { try { sessionStorage.removeItem(SS_KEY); } catch(_) {} }
  }
  document.getElementById('f').classList.remove('card-hidden');
})();

document.getElementById('f').addEventListener('submit', async e => {
  e.preventDefault();
  const err = document.getElementById('err'); err.textContent = '';
  const pw = document.getElementById('pw').value;
  try {
    const html = await tryDecrypt(pw);
    try { sessionStorage.setItem(SS_KEY, pw); } catch(_) {}
    reveal(html);
  } catch(_) {
    err.textContent = 'Contrase\\u00f1a incorrecta.';
  }
});
</script>
</body></html>
"""


if __name__ == "__main__":
    main()
