# Dell KVM hotkeys for Windows — one-line install (run in PowerShell as Administrator):
#   irm https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.ps1 | iex
#
# What it does:
#   1. Installs AutoHotkey v2 (winget) and NirSoft ControlMyMonitor (DDC/CI control).
#   2. Drops a hotkey script in your Startup folder: Ctrl+Alt+1 -> PC input, Ctrl+Alt+2 -> Mac input, Ctrl+Alt+0 -> toggle.
#
# Change inputs (VCP 0x60 codes): 15 = DisplayPort, 17 = HDMI 1, 18 = HDMI 2, 27 = USB-C
#   $env:PC_INPUT=15; $env:MAC_INPUT=27; irm https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.ps1 | iex
$ErrorActionPreference = 'Continue'
$PcInput  = if ($env:PC_INPUT)  { $env:PC_INPUT }  else { 17 }
$MacInput = if ($env:MAC_INPUT) { $env:MAC_INPUT } else { 27 }

function Say($m) { Write-Host "==> $m" -ForegroundColor Cyan }

Say "Installing AutoHotkey v2"
winget install --id AutoHotkey.AutoHotkey -e --silent --accept-package-agreements --accept-source-agreements | Out-Null

Say "Installing ControlMyMonitor"
$cmmDir = 'C:\Tools\ControlMyMonitor'
New-Item -ItemType Directory -Force $cmmDir | Out-Null
Invoke-WebRequest 'https://www.nirsoft.net/utils/controlmymonitor.zip' -OutFile "$env:TEMP\cmm.zip" -UserAgent 'Mozilla/5.0'
Expand-Archive "$env:TEMP\cmm.zip" $cmmDir -Force
if (-not (Test-Path "$cmmDir\ControlMyMonitor.exe")) { throw "ControlMyMonitor.exe not found after extract" }

Say "Writing startup hotkey script"
$ahk = @"
#Requires AutoHotkey v2.0
; DELL-KVM: switch monitor input over DDC/CI. Codes: $PcInput = PC, $MacInput = Mac
CMM := "$cmmDir\ControlMyMonitor.exe"
SetInput(code) {
    global CMM
    Run(Format('"{1}" /SetValue Primary 60 {2}', CMM, code), , "Hide")
}
^!1::SetInput($PcInput)
^!2::SetInput($MacInput)
^!0::SetInput($MacInput)   ; from the PC, "toggle" means go to the Mac
"@
$startup = [Environment]::GetFolderPath('Startup')
$file = Join-Path $startup 'Dell-KVM.ahk'
Set-Content -Encoding UTF8 -Path $file -Value $ahk
Get-Process -Name AutoHotkey* -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like '*Dell-KVM*' } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Process $file

Write-Host ""
Write-Host "Done."
Write-Host "  Ctrl+Alt+1  monitor -> PC  (input $PcInput)"
Write-Host "  Ctrl+Alt+2  monitor -> Mac (input $MacInput)"
Write-Host "  Ctrl+Alt+0  toggle"
Write-Host "If the Dell isn't your primary display, edit $file and replace 'Primary' with the monitor ID shown in ControlMyMonitor."
