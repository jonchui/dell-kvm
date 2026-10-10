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

Different ports or a third computer? `INPUTS` is a comma list of `<DDC code>:<label>` in hotkey order. Codes (VCP 0x60): 15 = DisplayPort, 17 = HDMI 1, 18 = HDMI 2, 27 = USB-C.
`INPUTS="17:Alienware,27:MacBook,18:Mac mini" curl … | bash` on macOS; `$env:INPUTS="17:Alienware,27:MacBook,18:Mac mini"; irm … | iex` on Windows. Run it on every machine.

Write-up: [How I built a true KVM](https://jonchui.github.io/dell-kvm/) · tested on a Dell U3419W with a MacBook Pro (USB-C) and an Alienware (HDMI 1 + USB-B).
