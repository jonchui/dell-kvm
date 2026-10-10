# Dell KVM hotkeys for Windows — one-line install (run in PowerShell as Administrator):
#   irm https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.ps1 | iex
#
# What it does:
#   1. Installs AutoHotkey v2 (winget) and NirSoft ControlMyMonitor (DDC/CI control).
#   2. Drops a hotkey script in your Startup folder: Ctrl+Alt+<n> switches the monitor to input n from the INPUTS list.
#
# INPUTS is a comma list of "<DDC code>:<label>" in hotkey order (Ctrl+Alt+1, +2, +3 ...).
# DDC codes (VCP 0x60): 15 = DisplayPort, 17 = HDMI 1, 18 = HDMI 2, 27 = USB-C
#   $env:INPUTS="17:Alienware,27:MacBook,18:Mac mini"; irm https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.ps1 | iex
$ErrorActionPreference = 'Continue'
$Inputs = if ($env:INPUTS) { $env:INPUTS } else { '17:PC,27:Mac' }

function Say($m) { Write-Host "==> $m" -ForegroundColor Cyan }

Say "Installing AutoHotkey v2"
winget install --id AutoHotkey.AutoHotkey -e --silent --accept-package-agreements --accept-source-agreements | Out-Null

Say "Installing ControlMyMonitor"
$cmmDir = 'C:\Tools\ControlMyMonitor'
New-Item -ItemType Directory -Force $cmmDir | Out-Null
if (-not (Test-Path "$cmmDir\ControlMyMonitor.exe")) {
  Invoke-WebRequest 'https://www.nirsoft.net/utils/controlmymonitor.zip' -OutFile "$env:TEMP\cmm.zip" -UserAgent 'Mozilla/5.0'
  Expand-Archive "$env:TEMP\cmm.zip" $cmmDir -Force
}
if (-not (Test-Path "$cmmDir\ControlMyMonitor.exe")) { throw "ControlMyMonitor.exe not found after extract" }

Say "Writing startup hotkey script"
$lines = @(
  '#Requires AutoHotkey v2.0',
  '; DELL-KVM: switch monitor input over DDC/CI (VCP 0x60).',
  "CMM := `"$cmmDir\ControlMyMonitor.exe`"",
  'SetInput(code) {',
  '    global CMM',
  "    Run(Format('`"{1}`" /SetValue Primary 60 {2}', CMM, code), , `"Hide`")",
  '}'
)
$n = 0; $summary = @()
foreach ($item in $Inputs.Split(',')) {
  $n++; $code, $label = $item.Trim().Split(':', 2)
  $lines += "^!${n}::SetInput($code)   ; $label"
  $summary += "Ctrl+Alt+$n -> $label (input $code)"
}
$startup = [Environment]::GetFolderPath('Startup')
$file = Join-Path $startup 'Dell-KVM.ahk'
Set-Content -Encoding UTF8 -Path $file -Value ($lines -join "`r`n")
Get-Process -Name AutoHotkey* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Process $file

Write-Host ""
Write-Host "Done. Hotkeys:"
$summary | ForEach-Object { Write-Host "  $_" }
Write-Host "If the Dell isn't your primary display, edit $file and replace 'Primary' with the monitor ID shown in ControlMyMonitor."
