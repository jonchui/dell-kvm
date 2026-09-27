# dell-kvm

One keyboard, one mouse, one Dell monitor, two computers. Uses the monitor's built-in KVM (USB Selection) plus a DDC/CI hotkey on each side to switch inputs — the keyboard follows the picture.

**macOS (Apple Silicon)** — Terminal:
```
curl -fsSL https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.sh | bash
```

**Windows** — PowerShell as Administrator:
```
irm https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.ps1 | iex
```

Hotkeys on both: `Ctrl+Alt+1` → PC · `Ctrl+Alt+2` → Mac · `Ctrl+Alt+0` → toggle.

Different ports? Input codes (VCP 0x60): 15 = DisplayPort, 17 = HDMI 1, 18 = HDMI 2, 27 = USB-C.
`PC_INPUT=15 MAC_INPUT=27 curl … | bash` on macOS; `$env:PC_INPUT=15; $env:MAC_INPUT=27; irm … | iex` on Windows.

Write-up: [How I built a true KVM](https://jonchui.github.io/dell-kvm/) · tested on a Dell U3419W with a MacBook Pro (USB-C) and an Alienware (HDMI 1 + USB-B).
