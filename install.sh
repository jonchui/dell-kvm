#!/usr/bin/env bash
# Dell KVM hotkeys for macOS (Apple Silicon) — one-line install.
#   curl -fsSL https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.sh | bash
#
# What it does:
#   1. Installs Homebrew (if missing), m1ddc (DDC/CI control) and Hammerspoon (hotkeys).
#   2. Writes a Hammerspoon config: Ctrl+Alt+1 -> PC input, Ctrl+Alt+2 -> Mac input, Ctrl+Alt+0 -> toggle.
#   3. Sets Hammerspoon to start at login and opens the Accessibility pane (one toggle you must flip).
#
# Change inputs for your monitor (VCP 0x60 codes): 15 = DisplayPort, 17 = HDMI 1, 18 = HDMI 2, 27 = USB-C
#   PC_INPUT=15 MAC_INPUT=27 curl -fsSL https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.sh | bash
set -euo pipefail

PC_INPUT="${PC_INPUT:-17}"     # HDMI 1
MAC_INPUT="${MAC_INPUT:-27}"   # USB-C
PC_LABEL="${PC_LABEL:-PC}"
MAC_LABEL="${MAC_LABEL:-Mac}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "This installer is for Apple Silicon Macs (m1ddc). On Intel, use BetterDisplay or ddcctl instead." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  say "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

say "Installing m1ddc + Hammerspoon"
brew list m1ddc >/dev/null 2>&1 || brew install m1ddc
[[ -d /Applications/Hammerspoon.app ]] || brew install --cask hammerspoon

say "Writing ~/.hammerspoon/init.lua"
mkdir -p "$HOME/.hammerspoon"
if [[ -f "$HOME/.hammerspoon/init.lua" ]] && ! grep -q 'DELL-KVM' "$HOME/.hammerspoon/init.lua"; then
  cp "$HOME/.hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua.bak.$(date +%Y%m%d%H%M%S)"
  say "Existing init.lua backed up"
fi
cat > "$HOME/.hammerspoon/init.lua" <<EOF
-- DELL-KVM: switch the monitor's input over DDC/CI. The monitor's own USB Selection
-- mapping (each video input -> a USB upstream) moves the keyboard/mouse with the picture.
local M1DDC = '/opt/homebrew/bin/m1ddc'
local PC, MAC = ${PC_INPUT}, ${MAC_INPUT}
local function setInput(code, label)
  local out, ok = hs.execute(M1DDC .. ' set input ' .. code)
  hs.alert.show(ok and ('Monitor → ' .. label) or ('DDC failed: ' .. tostring(out)))
end
hs.hotkey.bind({'ctrl','alt'}, '1', function() setInput(PC, '${PC_LABEL}') end)
hs.hotkey.bind({'ctrl','alt'}, '2', function() setInput(MAC, '${MAC_LABEL}') end)
hs.hotkey.bind({'ctrl','alt'}, '0', function()
  local cur = hs.execute(M1DDC .. ' get input')
  if cur and cur:match(tostring(MAC)) then setInput(PC, '${PC_LABEL}') else setInput(MAC, '${MAC_LABEL}') end
end)
hs.alert.show('KVM hotkeys: ⌃⌥1 ${PC_LABEL} · ⌃⌥2 ${MAC_LABEL} · ⌃⌥0 toggle')
EOF

say "Starting Hammerspoon at login"
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Hammerspoon.app", hidden:true}' >/dev/null 2>&1 || true
open -a Hammerspoon

say "Opening Accessibility settings — turn ON Hammerspoon there (needed for hotkeys)"
open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility' || true

cat <<EOF

Done.
  ⌃⌥1  monitor → ${PC_LABEL} (input ${PC_INPUT})
  ⌃⌥2  monitor → ${MAC_LABEL} (input ${MAC_INPUT})
  ⌃⌥0  toggle

Monitor side (once): Menu → USB Selection → map the PC's video input to the USB port its cable is in.
Test now: press ⌃⌥1 (after enabling Hammerspoon in Accessibility).
EOF
