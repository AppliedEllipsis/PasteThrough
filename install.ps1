#Requires -Version 5.1
<#
.SYNOPSIS
  One-command bootstrap for PasteThrough on Windows 10/11.

.DESCRIPTION
  Installs everything PasteThrough needs (via winget where possible):
    - Windows Terminal   (Microsoft.WindowsTerminal)
    - Node.js LTS        (OpenJS.NodeJS.LTS)
    - AutoHotkey v2      (AutoHotkey.AutoHotkey)
    - Git                (Git.Git)
    - zellij             (native-Windows MSI from the GitHub release)
  Then clones PasteThrough to C:\Tools\PasteThrough.

  Idempotent: skips anything already installed. Safe to re-run.

.PARAMETER InstallDir
  Where to clone PasteThrough. Default: C:\Tools\PasteThrough

.EXAMPLE
  ./install.ps1
  ./install.ps1 -InstallDir D:\Code\PasteThrough

.NOTES
  Run from a PowerShell window (NOT a bash shell). Right-click the .ps1 ->
  Run with PowerShell, or:
      powershell -ExecutionPolicy Bypass -File .\install.ps1
#>
[CmdletBinding()]
param(
  [string]$InstallDir = "C:\Tools\PasteThrough"
)

$ErrorActionPreference = "Stop"
$Repo = "https://github.com/AppliedEllipsis/PasteThrough.git"

function Write-Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "    OK  $msg" -ForegroundColor Green }
function Write-Info([string]$msg) { Write-Host "        $msg" -ForegroundColor DarkGray }
function Write-Warn2([string]$msg){ Write-Host "    !!  $msg" -ForegroundColor Yellow }

# --- 0. winget present? ------------------------------------------------------
Write-Step "Checking for winget"
$winget = (Get-Command winget.exe -ErrorAction SilentlyContinue)
if (-not $winget) {
  Write-Warn2 "winget not found."
  Write-Warn2 "Install 'App Installer' from the Microsoft Store, or:"
  Write-Warn2 "  https://github.com/microsoft/winget-cli/releases"
  Write-Warn2 "Then re-run this script. (On Windows 11 it is usually preinstalled.)"
  exit 1
}
Write-Ok "winget: $(& winget --version)"

# --- helper: winget install if missing ---------------------------------------
function Ensure-Winget([string]$Id, [string]$Friendly) {
  Write-Step "$Friendly ($Id)"
  $list = & winget list --id $Id -e --source winget 2>$null
  if ($list -match [regex]::Escape($Id)) {
    Write-Ok "$Friendly already installed -- skipping"
    return
  }
  Write-Info "Installing $Friendly ..."
  & winget install --id $Id -e --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
  if ($LASTEXITCODE -ne 0) {
    Write-Warn2 "winget install for $Id exited $LASTEXITCODE. It may still need a reboot."
  } else {
    Write-Ok "$Friendly installed"
  }
}

# --- 1-4. winget-managed tools ----------------------------------------------
Ensure-Winget "Microsoft.WindowsTerminal" "Windows Terminal"
Ensure-Winget "OpenJS.NodeJS.LTS"        "Node.js LTS"
Ensure-Winget "AutoHotkey.AutoHotkey"     "AutoHotkey v2"
Ensure-Winget "Git.Git"                   "Git"

# --- 5. zellij (native-Windows MSI from GitHub) ------------------------------
Write-Step "zellij (native-Windows MSI)"
$zellij = (Get-Command zellij.exe -ErrorAction SilentlyContinue)
if ($zellij -and (& zellij --version) -match "zellij") {
  Write-Ok "zellij already installed: $(& zellij --version)"
} else {
  $msiUrl = "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-pc-windows-msvc-installer.msi"
  $msi    = Join-Path $env:TEMP "zellij-installer.msi"
  Write-Info "Downloading $msiUrl"
  Invoke-WebRequest -Uri $msiUrl -OutFile $msi -UseBasicParsing
  Write-Info "Running MSI (may prompt for UAC) ..."
  $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msi`" /qb" -Wait -PassThru
  Remove-Item $msi -Force -ErrorAction SilentlyContinue
  if ($proc.ExitCode -eq 0) {
    Write-Ok "zellij MSI installed"
    Write-Warn2 "PATH updates need a NEW terminal window to take effect."
  } else {
    Write-Warn2 "zellij MSI install exited $($proc.ExitCode). Install manually from:"
    Write-Warn2 "  https://github.com/zellij-org/zellij/releases"
  }
}

# --- 6. pi (npm global) ------------------------------------------------------
Write-Step "pi coding agent"
# Refresh PATH for this session so node/npm just installed are visible.
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
$pi = (Get-Command pi.cmd -ErrorAction SilentlyContinue) -or (Get-Command pi -ErrorAction SilentlyContinue)
if ($pi) {
  Write-Ok "pi already installed"
} else {
  $npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
  if (-not $npm) {
    Write-Warn2 "npm not found on PATH yet -- open a NEW terminal and run:"
    Write-Warn2 "  npm install -g `@earendil-works/pi-coding-agent"
  } else {
    Write-Info "npm install -g @earendil-works/pi-coding-agent"
    & npm install -g "@earendil-works/pi-coding-agent"
    Write-Ok "pi installed"
  }
}

# --- 7. clone PasteThrough ---------------------------------------------------
Write-Step "Clone PasteThrough"
if (Test-Path "$InstallDir\pastethrough.ahk") {
  Write-Ok "Already present at $InstallDir -- skipping clone"
} else {
  $parent = Split-Path $InstallDir -Parent
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  Write-Info "git clone $Repo $InstallDir"
  & git clone $Repo $InstallDir
  if ($LASTEXITCODE -eq 0) { Write-Ok "Cloned to $InstallDir" }
  else { Write-Warn2 "git clone failed. Clone manually: git clone $Repo" }
}

# --- done --------------------------------------------------------------------
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Next:" -ForegroundColor Cyan
Write-Host "   1. Open a NEW Windows Terminal (so PATH updates)" -ForegroundColor White
Write-Host "   2. Double-click:  $InstallDir\pastethrough.ahk" -ForegroundColor White
Write-Host "   3. Run 'zellij' then 'pi', copy multiline text, press Ctrl+V" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
