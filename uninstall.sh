#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Materiality — uninstaller
#  Removes the shell, the symlinked scripts and (optionally) the state it
#  wrote. Never removes packages, fonts or the cursor — those are shared.
#
#  Usage:  ./uninstall.sh [--purge] [-y]
#    --purge   also delete ~/.local/state/expressive and ~/.local/share/expressive
#              (palette, wallpaper catalogue, clipboard history, alarms, …)
#    -y        don't ask
# ---------------------------------------------------------------------------
set -uo pipefail

CONF_ID="expressive"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
SHELL_DST="$XDG_CONFIG_HOME/quickshell/$CONF_ID"
BIN_DIR="$HOME/.local/bin"

PURGE=0 YES=0
for a in "$@"; do case "$a" in --purge) PURGE=1;; -y|--yes) YES=1;; esac; done

if [ -t 1 ]; then B=$'\e[1m'; Y=$'\e[33m'; G=$'\e[32m'; R=$'\e[0m'; else B='' Y='' G='' R=''; fi
ask() { [ "$YES" = 1 ] && return 0; read -r -p "   ${B}$1${R} [y/N] " x || true; [[ "$x" == [yY]* ]]; }

echo "${B}Materiality — uninstall${R}"

# stop a running instance
if command -v qs >/dev/null 2>&1 && qs -c "$CONF_ID" ipc call settings close >/dev/null 2>&1; then :; fi
pkill -f "qs -c $CONF_ID" 2>/dev/null || true
echo "   stopped any running instance"

# unlink helper scripts
n=0
for s in "$BIN_DIR"/expressive-* "$BIN_DIR"/matugen; do
  [ -L "$s" ] || continue
  case "$(readlink -f "$s")" in
    "$SHELL_DST"/*|"$HOME"/.cargo/bin/matugen) rm -f "$s"; n=$((n+1)) ;;
  esac
done
echo "   removed $n symlinks from $BIN_DIR"

# the shell itself
if [ -e "$SHELL_DST" ]; then
  if ask "delete $SHELL_DST ?"; then rm -rf "$SHELL_DST"; echo "   ${G}removed${R}"; else echo "   kept"; fi
fi

# cursor default (only if it points at Bibata we set)
if [ -f "$HOME/.icons/default/index.theme" ] && grep -q "Bibata-Modern-Classic" "$HOME/.icons/default/index.theme" 2>/dev/null; then
  if ask "reset the default cursor override (~/.icons/default) ?"; then rm -f "$HOME/.icons/default/index.theme"; echo "   ${G}removed${R}"; fi
fi

# state
if [ "$PURGE" = 1 ]; then
  rm -rf "$XDG_STATE_HOME/$CONF_ID" "$XDG_DATA_HOME/$CONF_ID"
  echo "   ${G}purged${R} state + data ($XDG_STATE_HOME/$CONF_ID, $XDG_DATA_HOME/$CONF_ID)"
else
  echo "   ${Y}kept${R} state in $XDG_STATE_HOME/$CONF_ID and $XDG_DATA_HOME/$CONF_ID  (use --purge to remove)"
fi

echo
echo "   Left alone: system packages, fonts in ~/.local/share/fonts, the Bibata cursor,"
echo "   and your niri config. Remove the 'spawn-at-startup \"qs\"' line there by hand."
