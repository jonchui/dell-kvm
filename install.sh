#!/usr/bin/env bash
# Dell KVM hotkeys for macOS (Apple Silicon) — one-line install.
#   curl -fsSL https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.sh | bash
#
# What it does:
#   1. Installs Homebrew (if missing), m1ddc (DDC/CI control) and Hammerspoon (hotkeys).
#   2. Writes a Hammerspoon config: Ctrl+Alt+<n> switches the monitor to input n from the INPUTS list.
#   3. Keeps Hammerspoon alive via launchd and opens the Accessibility pane (one toggle you must flip).
#
# INPUTS is a comma list of "<DDC code>:<label>" in hotkey order (Ctrl+Alt+1, +2, +3 ...).
# DDC codes (VCP 0x60): 15 = DisplayPort, 17 = HDMI 1, 18 = HDMI 2, 27 = USB-C
#   INPUTS="17:Alienware,27:MacBook,18:Mac mini" curl -fsSL https://raw.githubusercontent.com/jonchui/dell-kvm/main/install.sh | bash
set -euo pipefail
INPUTS="${INPUTS:-17:PC,27:Mac}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "This installer is for Apple Silicon Macs (m1ddc). On Intel, use BetterDisplay or ddcctl instead." >&2
  exit 1
fi

if [[ ! -x /opt/homebrew/bin/brew ]]; then
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
{
  cat <<'EOF'
-- DELL-KVM: switch the monitor's input over DDC/CI. The monitor's own USB Selection
-- mapping (each video input -> a USB upstream) moves the keyboard/mouse with the picture.
local M1DDC = '/opt/homebrew/bin/m1ddc'
local function setInput(code, label)
  local out, ok = hs.execute(M1DDC .. ' set input ' .. code)
  hs.alert.show(ok and ('Monitor → ' .. label) or ('DDC failed: ' .. tostring(out)))
end
EOF
  n=0; summary=""
  IFS=',' read -ra ITEMS <<< "$INPUTS"
  for item in "${ITEMS[@]}"; do
    n=$((n+1)); code="${item%%:*}"; label="${item#*:}"
    printf "hs.hotkey.bind({'ctrl','alt'}, '%d', function() setInput(%s, '%s') end)\n" "$n" "$code" "$label"
    summary+="⌃⌥${n} ${label} · "
  done
  printf "hs.alert.show('KVM: %s')\n" "${summary% · }"
} > "$HOME/.hammerspoon/init.lua"

say "Keeping Hammerspoon alive via launchd"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$HOME/Library/LaunchAgents/org.hammerspoon.keepalive.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>org.hammerspoon.keepalive</string>
  <key>ProgramArguments</key><array><string>/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon</string></array>
  <key>KeepAlive</key><true/>
  <key>RunAtLoad</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
</dict></plist>
EOF
osascript -e 'tell application "System Events" to delete login item "Hammerspoon"' >/dev/null 2>&1 || true
launchctl bootout "gui/$(id -u)/org.hammerspoon.keepalive" >/dev/null 2>&1 || true
pkill -x Hammerspoon >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/org.hammerspoon.keepalive.plist"

say "Opening Accessibility settings — turn ON Hammerspoon there (needed for hotkeys)"
open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility' || true

echo; echo "Done. Hotkeys:"
n=0; for item in "${ITEMS[@]}"; do n=$((n+1)); echo "  ⌃⌥${n}  monitor → ${item#*:} (input ${item%%:*})"; done
echo; echo "Monitor side (once): Menu → USB Selection → map each video input to the USB upstream port that computer's cable is in."
