#!/bin/bash
# Orion 1993: the ORION emblem as the screensaver text while the theme is active (used by the
# text fallback), Omarchy's own logo otherwise. Installed by install.sh (omarchy-orion-1993-screensaver).
THEME=orion-1993
ART=~/.local/share/orion-1993/page/orion.txt
DEST=~/.config/omarchy/branding/screensaver.txt

if [[ $1 == "$THEME" && -f $ART ]]; then
  mkdir -p "$(dirname "$DEST")"
  cp "$ART" "$DEST"
elif [[ -f $ART ]] && cmp -s "$DEST" "$ART"; then
  # back to what was there before install.sh (a custom text, if the user had one)
  ORIG=~/.local/share/orion-1993/screensaver.txt.orig
  [[ -f $ORIG ]] || ORIG=${OMARCHY_PATH:-/usr/share/omarchy}/logo.txt
  cp "$ORIG" "$DEST"
fi
