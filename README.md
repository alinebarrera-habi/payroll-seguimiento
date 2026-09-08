# Payroll · Tablero de Seguimiento (Habi)

Página publicada: **https://alinebarrera-habi.github.io/payroll-seguimiento/**

Este repo contiene **solo la versión cifrada** (`index.html`) del *Tablero de Seguimiento de
Payroll* de Finanzas Corporativas: headcount y costo empresa de Colombia y México, waterfalls de
entradas/salidas, movimientos por infra y subtag, comisiones y ejecución vs budget.

- El repo es público porque GitHub Pages lo exige; el contenido está cifrado con **AES-256-GCM
  (PBKDF2, 200k iteraciones)** y solo se abre con la contraseña. Sin ella la página es ilegible.
- La contraseña se comparte por fuera de este repo. **No la pegues en issues, commits ni chats
  abiertos.** El tablero trae datos de nómina persona por persona.
- El HTML fuente (sin cifrar) **no** está en el repo.

## Cómo se actualiza (cada cierre de mes)

1. Regenerar `Desktop\Tableros\Tablero_Payroll_Habi.html` con el toolkit del cierre
   (`Downloads\_cierre_ago\`: `gen_data20.ps1` → `DATA`, `gen4.ps1` → `ROSTER`, `swap_payload.ps1`,
   `verify_tablero.ps1`).
2. En esta carpeta:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File publish.ps1
   ```

   `publish.ps1` cifra el HTML con la contraseña de `config.local.ps1`, comprueba que la contraseña
   abre lo que escribió, commitea `index.html` y hace push. GitHub Pages lo sirve en ~1 minuto.

`config.local.ps1` (gitignored) tiene una sola línea: `$PAYROLL_PASSWORD = '...'`.

Fuente de datos: `Payroll Budget 2026 - VIVO*.xlsx` (Bridges Corp COL / HC COL / Corp MEX / Merbos +
`BBDD_TOTAL`), en USD con FX COP 3.700 / MXN 18,5.
