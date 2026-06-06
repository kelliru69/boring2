# Instala plantillas Godot 4.6.3 en D: y enlaza AppData (evita disco C: lleno).
# Ejecutar: powershell -ExecutionPolicy Bypass -File ".\scripts\install_godot_export_templates.ps1"

$ErrorActionPreference = "Stop"
$Version = "4.6.3.stable"
$Url = "https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz"
$ZipPath = "$env:TEMP\Godot_v4.6.3-stable_export_templates.zip"
$TpzPath = "$env:TEMP\Godot_v4.6.3-stable_export_templates.tpz"
$ExtractRoot = if ((Get-PSDrive C).Free -lt 500MB) { "E:\Temp\godot_templates_full" } else { "$env:TEMP\godot_templates_full" }
$TemplatesSrc = Join-Path $ExtractRoot "templates"
$TargetOnD = "D:\Programas\Godot_v4.6.3-stable_win64.exe~1\GODOTGAMES\godot_export_templates\$Version"
$AppDataLink = Join-Path $env:APPDATA "Godot\export_templates\$Version"
$MinExeBytes = 40MB

function Test-DiskSpace {
    $cFree = (Get-PSDrive C).Free
    Write-Host "Espacio libre en C: $([math]::Round($cFree/1MB,0)) MB" -ForegroundColor $(if ($cFree -lt 500MB) { "Red" } else { "Green" })
    if ($cFree -lt 500MB) {
        Write-Host "AVISO: C: casi lleno. Las plantillas se guardan en D: y se enlazan a AppData." -ForegroundColor Yellow
    }
}

Test-DiskSpace

# --- Descarga (si falta el zip) ---
if (-not (Test-Path $ZipPath) -or (Get-Item $ZipPath).Length -lt 100MB) {
    if (Test-Path $TpzPath) { Remove-Item -Force $TpzPath }
    Write-Host "Descargando ~1.2 GB..." -ForegroundColor Green
    curl.exe -L --progress-bar -o $TpzPath $Url
    if ($LASTEXITCODE -ne 0) { throw "Descarga fallida" }
    Copy-Item -Force $TpzPath $ZipPath
}

# --- Extraer a E: o TEMP (no a C:) ---
Remove-Item -Recurse -Force $ExtractRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $ExtractRoot | Out-Null
Write-Host "Extrayendo (varios minutos)..." -ForegroundColor Green
tar -xf $ZipPath -C $ExtractRoot
if (-not (Test-Path "$TemplatesSrc\windows_release_x86_64.exe")) {
    throw "Extraccion fallida"
}

# --- Copiar solo Windows a D: (~620 MB) ---
Remove-Item -Recurse -Force $TargetOnD -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $TargetOnD | Out-Null
Copy-Item "$TemplatesSrc\windows_*.exe" $TargetOnD -Force
Copy-Item "$TemplatesSrc\icudt_godot.dat", "$TemplatesSrc\version.txt" $TargetOnD -Force

$exe = Get-Item "$TargetOnD\windows_release_x86_64.exe"
if ($exe.Length -lt $MinExeBytes) { throw "EXE invalido en D:" }
Write-Host "Plantillas en D: OK ($([math]::Round($exe.Length/1MB,1)) MB)" -ForegroundColor Green

# --- Enlace AppData -> D: (Godot busca aqui) ---
if (Test-Path $AppDataLink) {
    $item = Get-Item $AppDataLink -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        cmd /c rmdir "$AppDataLink"
    } else {
        Remove-Item -Recurse -Force $AppDataLink
    }
}
$parent = Split-Path $AppDataLink -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
cmd /c mklink /J "$AppDataLink" "$TargetOnD"
if (-not (Test-Path "$AppDataLink\windows_release_x86_64.exe")) {
    throw "Enlace junction fallo. Ejecuta PowerShell como administrador o crea el enlace a mano."
}

Write-Host ""
Write-Host "LISTO. Godot usara:" -ForegroundColor Green
Write-Host "  $AppDataLink"
Write-Host "  -> $TargetOnD"
Write-Host ""
Write-Host "Libera espacio en C: (recomendado). Limpieza temporal opcional:" -ForegroundColor Yellow
Write-Host "  Remove-Item -Recurse -Force '$ExtractRoot'"
Write-Host "  Remove-Item -Force '$ZipPath','$TpzPath' -ErrorAction SilentlyContinue"
