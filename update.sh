#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Materiality — update an already-installed copy
#  https://github.com/b4demus/materiality-shell
#
#  Pulls the latest commit, re-deploys shell/ into
#  ~/.config/quickshell/expressive *in place* (so the running shell
#  hot-reloads), refreshes the helper-script symlinks, and nudges a reload.
#  Your settings, palette, wallpapers and niri config are never touched —
#  they live in ~/.local/state/expressive and ~/.config/niri.
#
#  Usage:  ./update.sh [options]
#    --no-pull    don't `git pull` — deploy whatever is checked out now
#    --restart    hard-restart the shell (qs kill + relaunch) instead of
#                 leaning on hot-reload. Needed when an update adds a new
#                 IPC handler (hot-reload won't register those).
#    --fonts      also re-run the font + cursor step from install.sh
#    -h, --help   this text
# ---------------------------------------------------------------------------
set -uo pipefail

REPO_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)"
CONF_ID="expressive"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SHELL_DST="$XDG_CONFIG_HOME/quickshell/$CONF_ID"
BIN_DIR="$HOME/.local/bin"

DO_PULL=1 DO_RESTART=0 DO_FONTS=0

if [ -t 1 ]; then B=$'\e[1m'; DIM=$'\e[2m'; GRN=$'\e[32m'; YLW=$'\e[33m'; RED=$'\e[31m'; BLU=$'\e[34m'; RST=$'\e[0m'
else B='' DIM='' GRN='' YLW='' RED='' BLU='' RST=''; fi
say()  { printf '%s\n' "${B}${BLU}::${RST} ${B}$*${RST}"; }
info() { printf '   %s\n' "$*"; }
ok()   { printf '   %s%s%s\n' "$GRN" "$*" "$RST"; }
warn() { printf '   %s! %s%s\n' "$YLW" "$*" "$RST"; }
die()  { printf '%s\n' "${B}${RED}✗ $*${RST}" >&2; exit 1; }

usage() {
  cat <<'EOF'
Materiality — update an installed copy

  ./update.sh [options]

    --no-pull    don't `git pull` — deploy whatever is checked out now
    --restart    hard-restart the shell (qs kill + relaunch) instead of
                 hot-reload. Needed when an update changes a keybind or
                 adds an IPC handler.
    --fonts      also re-run the font + cursor step
    -h, --help   this text

Pulls the latest commit and re-deploys shell/ into
~/.config/quickshell/expressive in place. Settings, palette, wallpapers
and your niri config are left alone.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --no-pull) DO_PULL=0 ;;
    --restart) DO_RESTART=1 ;;
    --fonts)   DO_FONTS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

[ "$(id -u)" -eq 0 ] && die "run as your normal user, not root."
[ -d "$SHELL_DST" ] || die "no install at $SHELL_DST — run ./install.sh first."

# ---- 1. pull ------------------------------------------------------------
if [ "$DO_PULL" = 1 ]; then
  say "Fetching updates"
  if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    before="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo '?')"
    if git -C "$REPO_DIR" pull --ff-only --quiet; then
      after="$(git -C "$REPO_DIR" rev-parse --short HEAD)"
      if [ "$before" = "$after" ]; then
        ok "already up to date ($after)"
      else
        ok "$before → $after"
        git -C "$REPO_DIR" --no-pager log --oneline --no-decorate "$before..$after" | sed 's/^/   /'
      fi
    else
      warn "git pull failed (local changes? not on a branch?) — deploying the current checkout."
    fi
  else
    warn "$REPO_DIR is not a git checkout — deploying as-is. Re-clone to get future updates."
  fi
else
  say "Skipping git pull (--no-pull)"
fi

# ---- 2. deploy in place ----------------------------------------------------
say "Deploying  →  $SHELL_DST"
if command -v rsync >/dev/null 2>&1; then
  # in place, delete removed files, but keep the install marker, a local git
  # checkout (if you cloned straight into the config dir) and any caches
  rsync -a --delete \
    --exclude='.materiality' --exclude='.git/' \
    --exclude='__pycache__/' --exclude='*.pyc' \
    "$REPO_DIR/shell/" "$SHELL_DST/"
else
  cp -a "$REPO_DIR/shell/." "$SHELL_DST/"
  find "$SHELL_DST" -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true
  warn "rsync not found — used cp; files deleted upstream won't be removed locally."
fi
printf 'installed by materiality-shell/update.sh on %s\n' "$(date)" > "$SHELL_DST/.materiality"
ok "$(find "$SHELL_DST" -type f -not -name '.materiality' | wc -l) files in place"

# ---- 3. refresh script symlinks -----------------------------------------
say "Helper scripts"
mkdir -p "$BIN_DIR"
n=0
for s in "$SHELL_DST"/scripts/expressive-*; do
  [ -f "$s" ] || continue
  chmod +x "$s"
  ln -sf "$s" "$BIN_DIR/$(basename "$s")"
  n=$((n+1))
done
chmod +x "$SHELL_DST"/scripts/* 2>/dev/null || true
ok "$n linked"
# drop stale links whose target no longer exists
for l in "$BIN_DIR"/expressive-*; do
  [ -L "$l" ] && [ ! -e "$l" ] && { rm -f "$l"; info "removed stale link $(basename "$l")"; }
done

# ---- 3b. fish config -------------------------------------------------------
if [ -d "$REPO_DIR/fish" ]; then
  say "Fish config"
  fdst="$XDG_CONFIG_HOME/fish"
  if [ -f "$fdst/config.fish" ] && ! head -1 "$fdst/config.fish" | grep -q 'expressive.*fish shell config'; then
    cp "$fdst/config.fish" "$fdst/config.fish.bak.$(date +%s)"
    warn "your existing config.fish was backed up"
  fi
  mkdir -p "$fdst/conf.d" "$fdst/functions"
  cp -f "$REPO_DIR/fish/config.fish"        "$fdst/config.fish"
  cp -f "$REPO_DIR"/fish/conf.d/*.fish      "$fdst/conf.d/"
  cp -f "$REPO_DIR"/fish/functions/*.fish   "$fdst/functions/"
  ok "prompt + palette colours refreshed (login shell unchanged)"
fi

# ---- 4. optional font/cursor refresh -----------------------------------
if [ "$DO_FONTS" = 1 ]; then
  say "Re-running fonts + cursor"
  "$REPO_DIR/install.sh" --no-packages -y >/dev/null 2>&1 && ok "done" || warn "font/cursor step reported problems — run ./install.sh by hand"
fi

# ---- 4b. re-apply the palette ----------------------------------------------
# The theme engine and its scheme files ship with the shell, so an update can
# change how the palette is generated. Cheap and idempotent.
if [ -x "$SHELL_DST/scripts/expressive-theme" ]; then
  say "Palette"
  if "$SHELL_DST/scripts/expressive-theme" >/dev/null 2>&1; then
    ok "regenerated from your current wallpaper / scheme"
  else
    warn "expressive-theme failed — run it by hand to see why"
  fi
fi

# ---- 5. reload --------------------------------------------------------------
say "Reload"
if pgrep -f "qs -c $CONF_ID" >/dev/null 2>&1; then
  if [ "$DO_RESTART" = 1 ]; then
    qs -c "$CONF_ID" kill >/dev/null 2>&1 || pkill -f "qs -c $CONF_ID" || true
    sleep 1
    if command -v setsid >/dev/null 2>&1; then
      setsid -f qs -c "$CONF_ID" </dev/null >/dev/null 2>&1
    else
      nohup qs -c "$CONF_ID" >/dev/null 2>&1 &
      disown 2>/dev/null || true
    fi
    ok "restarted"
  else
    # Quickshell watches the config dir and hot-reloads on change; touch the
    # entrypoint so it definitely notices this batch of files.
    touch "$SHELL_DST/shell.qml"
    ok "hot-reloading (run with --restart if a bind/IPC handler changed)"
  fi
else
  warn "shell isn't running — start it with:  qs -c $CONF_ID &"
fi

echo
say "${GRN}Updated.${RST}"
