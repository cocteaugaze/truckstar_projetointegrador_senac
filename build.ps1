# ============================================================
#  Truckstar - Build automatizado
#  Gera: installer_output/TruckstarSetup-X.Y.Z.exe
#
#  Pre-requisitos (uma vez):
#    py -m pip install -r requirements.txt -r dev-requirements.txt
#    winget install JRSoftware.InnoSetup
#
#  Uso:
#    .\build.ps1            # build padrao
#    .\build.ps1 -Clean     # limpa build/dist/installer_output antes
# ============================================================

param(
    [switch]$Clean
)

# Mantém Continue (default) — PyInstaller e ISCC emitem progresso via stderr,
# o que faz PowerShell 5.1 abortar com "Stop". Validamos via $LASTEXITCODE.
$ErrorActionPreference = "Continue"

$Root = $PSScriptRoot
Set-Location $Root

# --- Limpeza opcional ---
if ($Clean) {
    Write-Host "[clean] Removendo build/, dist/, installer_output/..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force build, dist, installer_output, Truckstar.spec -ErrorAction SilentlyContinue
}

# --- Localiza ISCC ---
$ISCC = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $ISCC) {
    Write-Host "ERRO: Inno Setup nao encontrado." -ForegroundColor Red
    Write-Host "Instale com: winget install JRSoftware.InnoSetup"
    exit 1
}
Write-Host "[ok] Inno Setup: $ISCC" -ForegroundColor Green

# --- Build PyInstaller ---
Write-Host ""
Write-Host "[1/2] PyInstaller - gerando .exe..." -ForegroundColor Cyan
$pyArgs = @(
    "-m", "PyInstaller", "--noconfirm", "--windowed",
    "--icon=assets/truckstar.ico",
    "--name=Truckstar",
    "--collect-data", "customtkinter",
    "--collect-data", "reportlab",
    "--exclude-module", "config",
    "main.py"
)
& py @pyArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: PyInstaller falhou." -ForegroundColor Red
    exit 1
}
Write-Host "[ok] Bundle em: dist\Truckstar\" -ForegroundColor Green

# --- Sanity check: config.py com credencial vazou pro bundle? ---
# Procura pelo padrao "RESEND_API_KEY = 're_xxx...'" (atribuicao no config.py)
# Strings 're_xxx' soltas em DLLs nativos sao falso-positivo conhecido.
Write-Host ""
Write-Host "[check] Procurando config.py vazado no bundle..." -ForegroundColor Cyan
$leaks = @()
Get-ChildItem -Path dist\Truckstar -Recurse -File | Where-Object {
    $_.Extension -in @('.pyc', '.py', '.pyz', '.zip', '')  -or
    $_.Name -match 'config'
} | ForEach-Object {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $text = [System.Text.Encoding]::ASCII.GetString($bytes)
        # Procura por DB_PASSWORD ou RESEND_API_KEY seguidos de string nao vazia
        if ($text -match "RESEND_API_KEY.{0,5}['""]re_[A-Za-z0-9_]{20,}" -or
            $text -match "DB_PASSWORD.{0,5}['""][^'""]{5,}") {
            $leaks += $_.FullName
        }
    } catch {}
}
if ($leaks.Count -gt 0) {
    Write-Host "AVISO: Padrao de config.py vazado encontrado em:" -ForegroundColor Yellow
    $leaks | ForEach-Object { Write-Host "  $_" }
    Write-Host "Revise antes de distribuir o instalador!" -ForegroundColor Yellow
} else {
    Write-Host "[ok] Nenhum vazamento detectado." -ForegroundColor Green
}

# --- Build Inno Setup ---
Write-Host ""
Write-Host "[2/2] Inno Setup - gerando instalador..." -ForegroundColor Cyan
& $ISCC "installer\truckstar.iss"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Inno Setup falhou." -ForegroundColor Red
    exit 1
}

# --- Output ---
$installer = Get-ChildItem installer_output\TruckstarSetup-*.exe -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($installer) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host " Build concluido com sucesso!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host " Instalador: $($installer.FullName)"
    Write-Host " Tamanho:    $([math]::Round($installer.Length / 1MB, 1)) MB"
    Write-Host ""
    Write-Host " Distribua esse .exe para clientes."
    Write-Host "================================================" -ForegroundColor Green
}
