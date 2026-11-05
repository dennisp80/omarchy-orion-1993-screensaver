#!/bin/bash
# Installs the Orion 1993 screensaver for the orion-1993 Omarchy theme
# (https://github.com/dennisp80/omarchy-orion-1993-theme). A theme may not ship code, so the
# screensaver lives in this repository of its own. Undo everything with ./uninstall.sh.
# Also upgrades an install made by the theme's old screensaver/install.sh (before 2026-11).
#
#   ./install.sh      explain and ask first
#   ./install.sh -y   no questions

set -e
HERE=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
DATA=~/.local/share/orion-1993
ENV=~/.config/uwsm/env
HOOK=~/.config/omarchy/hooks/theme-set.d/orion-1993-screensaver.sh
BRANDING=~/.config/omarchy/branding/screensaver.txt
MARK="# orion-1993 screensaver (remove with omarchy-orion-1993-screensaver/uninstall.sh)"
OLD_MARK="# orion-1993 screensaver (remove with the theme's screensaver/uninstall.sh)"
HYPR_LUA=~/.config/hypr/hyprland.lua
LUA_BEGIN="-- >>> orion-1993 screensaver (remove with omarchy-orion-1993-screensaver/uninstall.sh) >>>"
OLD_LUA_BEGIN="-- >>> orion-1993 screensaver (remove with the theme's screensaver/uninstall.sh) >>>"
LUA_END="-- <<< orion-1993 screensaver <<<"

cat <<EOF
Orion 1993 screensaver: this will

  1. copy a small wrapper to        $DATA/bin/omarchy-screensaver
     and the screensaver page to     $DATA/page/
     It runs only while the orion-1993 theme is active; with any other theme it hands
     straight over to Omarchy's own screensaver.
  2. put that folder first on PATH  in $ENV and in your Hyprland config (~/.config/hypr/),
     (hyprland.lua, a clearly marked block). Omarchy 4's Hyprland defaults put
     /usr/share/omarchy/bin first for everything Hyprland starts, so the uwsm line alone is not enough.
  3. add a theme-set hook           $HOOK
     It switches the screensaver text to the ORION emblem for this theme and back again.
  4. back up your current screensaver text to $DATA/screensaver.txt.orig

The screensaver itself is a web page shown in a kiosk window of Chromium, Chrome or Brave.
Esc, any key or moving the mouse ends it.

EOF

if ! command -v chromium >/dev/null && ! command -v google-chrome-stable >/dev/null && ! command -v brave >/dev/null; then
  echo "Note: no Chromium, Chrome or Brave found. The screensaver will fall back to Omarchy's"
  echo "text effects in the theme's colors until one is installed (omarchy pkg add chromium)."
  echo
fi

if [[ $1 != "-y" ]]; then
  if command -v gum >/dev/null; then
    gum confirm "Install the Orion 1993 screensaver?" || exit 1
  else
    read -rp "Install the Orion 1993 screensaver? [y/N] " a
    [[ $a == [yY]* ]] || exit 1
  fi
fi

install -D -m 755 "$HERE/bin/omarchy-screensaver" "$DATA/bin/omarchy-screensaver"
# a fresh copy of the page, so files dropped in a new version don't linger
rm -rf "$DATA/page"
install -d "$DATA/page"
install -m 644 "$HERE"/page/* "$DATA/page/"

if [[ -f $BRANDING && ! -f $DATA/screensaver.txt.orig ]]; then
  cp "$BRANDING" "$DATA/screensaver.txt.orig"
fi

mkdir -p "$(dirname "$ENV")"
touch "$ENV"
# an install from the theme's old screensaver/install.sh: point its marker at this repository
# (written through, so a symlinked file from a dotfiles repo stays a symlink)
if grep -qF "$OLD_MARK" "$ENV"; then
  sed "s|$OLD_MARK|$MARK|" "$ENV" >"$ENV.tmp" && { cat "$ENV.tmp" >"$ENV"; rm -f "$ENV.tmp"; }
fi
if ! grep -qF "$MARK" "$ENV"; then
  printf '\n%s\nexport PATH="$HOME/.local/share/orion-1993/bin:$PATH"\n' "$MARK" >>"$ENV"
fi

# Hyprland: Omarchy 4's default/hypr/envs.lua puts $OMARCHY_PATH/bin first on PATH for everything
# Hyprland launches (the screensaver included), so the wrapper must come before it there too.
# (Older Omarchy with hyprland.conf doesn't do that – the uwsm line above is enough there.)
if [[ -f $HYPR_LUA ]]; then
  if grep -qF -e "$OLD_LUA_BEGIN" "$HYPR_LUA"; then
    sed "s|$OLD_LUA_BEGIN|$LUA_BEGIN|" "$HYPR_LUA" >"$HYPR_LUA.tmp" &&
      { cat "$HYPR_LUA.tmp" >"$HYPR_LUA"; rm -f "$HYPR_LUA.tmp"; }
  fi
  if ! grep -qF -e "$LUA_BEGIN" "$HYPR_LUA"; then
    cat >>"$HYPR_LUA" <<'LUA'

-- >>> orion-1993 screensaver (remove with omarchy-orion-1993-screensaver/uninstall.sh) >>>
do
  local wrapper = os.getenv("HOME") .. "/.local/share/orion-1993/bin"
  local omarchy_bin = (os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/bin"
  local kept = { wrapper, omarchy_bin }
  for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
    if entry ~= wrapper and entry ~= omarchy_bin then table.insert(kept, entry) end
  end
  hl.env("PATH", table.concat(kept, ":"))
end
-- <<< orion-1993 screensaver <<<
LUA
  fi
fi

install -D -m 755 "$HERE/theme-set-hook.sh" "$HOOK"

# already on the theme: switch the text now instead of at the next theme change
current=$(cat ~/.local/state/omarchy/current/theme.name 2>/dev/null || true)
bash "$HOOK" "$current" || true

# apply the new PATH to the running Hyprland right away
command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true

if [[ ! -d ~/.config/omarchy/themes/orion-1993 ]]; then
  echo
  echo "Note: the orion-1993 theme isn't installed. The screensaver only runs while it is active:"
  echo "  omarchy theme install https://github.com/dennisp80/omarchy-orion-1993-theme"
fi

echo
echo "Done. Try it with:  omarchy-launch-screensaver force"
echo "(If Omarchy's own screensaver still shows, log out and back in once.)"
