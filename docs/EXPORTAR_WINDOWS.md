# Exportar boring.exe en Windows (Godot 4.6.3)

## Causa habitual de .exe en 0 MB

1. **Disco C: lleno** — Godot guarda plantillas en `%APPDATA%\Godot\export_templates\` (en C:).
   - Si C: tiene pocos MB libres, los `.exe` quedan en **0 bytes** y falla *cabecera corrupta*.
2. **Antivirus** — borra o bloquea `windows_release_x86_64.exe` al descargar.

Comprueba espacio en C::

```powershell
(Get-PSDrive C).Free / 1MB
```

Necesitas **varios cientos de MB libres** en C: **o** usar el script que instala en **D:** y enlaza AppData.

---

## Solución rápida (script del proyecto)

En PowerShell, desde la carpeta del juego:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\install_godot_export_templates.ps1"
```

Eso descarga plantillas, las copia a:

`D:\Programas\Godot_v4.6.3-stable_win64.exe~1\GODOTGAMES\godot_export_templates\4.6.3.stable\`

y crea un **enlace** en AppData para que Godot las encuentre.

Verifica:

```powershell
(Get-Item "$env:APPDATA\Godot\export_templates\4.6.3.stable\windows_release_x86_64.exe").Length / 1MB
```

Debe ser **~100**, no 0.

---

## Liberar espacio en C: (importante)

Tu editor y descargas usan C:. Libera al menos **2–5 GB**:

- Liberador de espacio en disco de Windows  
- Vaciar papelera  
- Borrar `%TEMP%` y `%LOCALAPPDATA%\Temp`  
- Desinstalar programas grandes que no uses  

Cambiar carpeta de descargas de Godot (opcional):  
**Editor → Editor Settings** → busca `export template download` → pon una ruta en **D:**, por ejemplo:

`D:/Programas/Godot_v4.6.3-stable_win64.exe~1/GODOTGAMES/godot_export_templates/downloads`

---

## Exportar el juego

1. Abre Godot 4.6.3.
2. **Project → Export…** → **boring**.
3. Ruta: `build/boring.exe`.
4. **Embed PCK:** desactivado → genera `boring.exe` + `boring.pck`.
5. **Export Project**.

Para GitHub Releases: zip con `boring.exe` y `boring.pck`.

---

## Instalación manual

1. https://github.com/godotengine/godot/releases/tag/4.6.3-stable  
2. Descarga `Godot_v4.6.3-stable_export_templates.tpz` (~1.2 GB).  
3. Renómbralo a `.zip` y extrae la carpeta `templates` en **D:** (no en C: si está lleno).  
4. Crea enlace de directorio (CMD como usuario):

```cmd
rmdir /S /Q "%APPDATA%\Godot\export_templates\4.6.3.stable"
mklink /J "%APPDATA%\Godot\export_templates\4.6.3.stable" "D:\Programas\Godot_v4.6.3-stable_win64.exe~1\GODOTGAMES\godot_export_templates\4.6.3.stable"
```
