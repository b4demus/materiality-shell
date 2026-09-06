#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  Materiality — cross-distro installer
#  https://github.com/b4demus/materiality-shell
#
#  Installs the Quickshell shell, its helper scripts, fonts, the Bibata
#  cursor and (optionally) an example niri config. Tries to pull the three
#  packages that aren't everywhere yet — quickshell, niri, matugen — through
#  whatever package manager it can find, and tells you exactly what to do by
#  hand when it can't.
#
#  It also deploys the fish config (kaomoji prompt, clock, cmd/session timers,
#  palette colours) and makes fish the login shell.
#
#  Usage:   ./install.sh [options]        (run --help for the current list)
#    --no-packages   don't touch the system package manager
#    --no-fonts      skip the font download
#    --no-cursor     skip the Bibata download
#    --no-shell      install the fish config but don't chsh to it
#    --niri          also install niri/config.kdl (backs up any existing one)
#    -y, --yes       assume "yes" to every prompt
#    --update        run update.sh instead
#    --uninstall     run uninstall.sh instead
# ---------------------------------------------------------------------------
set -uo pipefail

# ---- constants ------------------------------------------------------------
REPO_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)"
CONF_ID="expressive"                                   # the `qs -c <id>` name
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
SHELL_DST="$XDG_CONFIG_HOME/quickshell/$CONF_ID"
BIN_DIR="$HOME/.local/bin"
FONT_DIR="$XDG_DATA_HOME/fonts"
ICON_DIR="$XDG_DATA_HOME/icons"
STATE_DIR="$XDG_STATE_HOME/$CONF_ID"
DATA_DIR="$XDG_DATA_HOME/$CONF_ID"

CURSOR_NAME="Bibata-Modern-Classic"
CURSOR_VER="2.0.7"
CURSOR_SIZE=24
JBMONO_VER="2.304"

# ---- options -----------------------------------------------------------
DO_PACKAGES=1 DO_FONTS=1 DO_CURSOR=1 DO_NIRI=0 DO_SHELL=1 ASSUME_YES=0

# ---- pretty output ---------------------------------------------------------
if [ -t 1 ]; then
  B=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; BLU=$'\e[34m'; RST=$'\e[0m'
else
  B='' DIM='' RED='' GRN='' YLW='' BLU='' RST=''
fi
say()  { printf '%s\n' "${B}${BLU}::${RST} ${B}$*${RST}"; }
info() { printf '   %s\n' "$*"; }
ok()   { printf '   %s%s%s\n' "$GRN" "$*" "$RST"; }
warn() { printf '   %s! %s%s\n' "$YLW" "$*" "$RST"; }
die()  { printf '%s\n' "${B}${RED}✗ $*${RST}" >&2; exit 1; }

usage() {
  cat <<'EOF'
Materiality — cross-distro installer

  ./install.sh [options]

    --no-packages   don't touch the system package manager (deps are on you)
    --no-fonts      skip downloading the fonts
    --no-cursor     skip downloading the Bibata cursor
    --no-shell      install the fish config but don't chsh to it
    --niri          also install niri/config.kdl (backs up any existing one)
    -y, --yes       assume "yes" to every prompt
    --update        run update.sh instead (pull + redeploy)
    --uninstall     run uninstall.sh instead
    -h, --help      this text

Installs the shell into ~/.config/quickshell/expressive, symlinks the helper
scripts into ~/.local/bin, fetches fonts + cursor, deploys the fish config
(kaomoji prompt, clock, timers, palette colours) and makes fish your login
shell, and (if you have no niri config) installs the example one.
Idempotent — safe to re-run.
EOF
}

ask() {  # ask "question" -> 0 (yes) / 1 (no); default yes
  [ "$ASSUME_YES" = 1 ] && return 0
  local a; read -r -p "   ${B}$1${RST} [Y/n] " a || true
  case "$a" in [nN]*) return 1;; *) return 0;; esac
}

# ---- arg parsing ---------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --no-packages) DO_PACKAGES=0 ;;
    --no-fonts)    DO_FONTS=0 ;;
    --no-cursor)   DO_CURSOR=0 ;;
    --no-shell)    DO_SHELL=0 ;;
    --niri)        DO_NIRI=1 ;;
    -y|--yes)      ASSUME_YES=1 ;;
    --update)      shift; exec "$REPO_DIR/update.sh" "$@" ;;
    --uninstall)   exec "$REPO_DIR/uninstall.sh" ;;
    -h|--help)     usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

[ "$(id -u)" -eq 0 ] && die "run this as your normal user, not root — it installs into \$HOME."
command -v curl >/dev/null 2>&1 || die "curl is required to bootstrap. Install it and re-run."

# =========================================================================
#  package manager
# =========================================================================
PM='' PM_INSTALL='' SUDO=''
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO=sudo

detect_pm() {
  if   command -v pacman   >/dev/null 2>&1; then PM=pacman;  PM_INSTALL="$SUDO pacman -S --needed --noconfirm"
  elif command -v dnf      >/dev/null 2>&1; then PM=dnf;     PM_INSTALL="$SUDO dnf install -y"
  elif command -v apt-get  >/dev/null 2>&1; then PM=apt;     PM_INSTALL="$SUDO apt-get install -y"
  elif command -v zypper   >/dev/null 2>&1; then PM=zypper;  PM_INSTALL="$SUDO zypper --non-interactive install"
  elif command -v xbps-install >/dev/null 2>&1; then PM=xbps; PM_INSTALL="$SUDO xbps-install -Sy"
  elif command -v apk      >/dev/null 2>&1; then PM=apk;     PM_INSTALL="$SUDO apk add"
  elif command -v emerge   >/dev/null 2>&1; then PM=emerge;  PM_INSTALL="$SUDO emerge -q"
  else PM=unknown; fi
}

# Package names per manager. Echoes a space-separated list for $PM.
# Includes the Roboto / JetBrains Mono fonts where the distro ships them —
# only Material Symbols always has to be downloaded.
pkg_list() {
  case "$PM" in
    pacman) echo "fish jq alacritty python python-pillow wl-clipboard zenity libnotify networkmanager pipewire wireplumber pipewire-pulse brightnessctl power-profiles-daemon upower polkit mate-polkit xdg-desktop-portal xdg-desktop-portal-gtk fontconfig curl unzip tar gammastep swayidle ttf-roboto ttf-roboto-mono ttf-jetbrains-mono" ;;
    dnf)    echo "fish jq alacritty python3 python3-pillow wl-clipboard zenity libnotify NetworkManager pipewire wireplumber pipewire-pulseaudio brightnessctl power-profiles-daemon upower polkit mate-polkit xdg-desktop-portal xdg-desktop-portal-gtk fontconfig curl unzip tar gammastep swayidle google-roboto-fonts google-roboto-mono-fonts jetbrains-mono-fonts" ;;
    apt)    echo "fish jq alacritty python3 python3-pil wl-clipboard zenity libnotify-bin network-manager pipewire wireplumber pipewire-pulse brightnessctl power-profiles-daemon upower policykit-1-gnome xdg-desktop-portal xdg-desktop-portal-gtk fontconfig curl unzip tar gammastep swayidle fonts-roboto fonts-jetbrains-mono" ;;
    zypper) echo "fish jq alacritty python3 python3-Pillow wl-clipboard zenity libnotify-tools NetworkManager pipewire wireplumber pipewire-pulseaudio brightnessctl power-profiles-daemon upower polkit mate-polkit xdg-desktop-portal xdg-desktop-portal-gtk fontconfig curl unzip tar gammastep swayidle google-roboto-fonts jetbrains-mono-fonts" ;;
    xbps)   echo "fish jq alacritty python3 python3-Pillow wl-clipboard zenity libnotify NetworkManager pipewire wireplumber brightnessctl power-profiles-daemon upower polkit mate-polkit xdg-desktop-portal xdg-desktop-portal-gtk fontconfig curl unzip tar gammastep swayidle font-roboto-ttf" ;;
    apk)    echo "fish jq alacritty python3 py3-pillow wl-clipboard zenity libnotify networkmanager pipewire wireplumber brightnessctl power-profiles-daemon upower polkit xdg-desktop-portal xdg-desktop-portal-gtk fontconfig curl unzip tar gammastep swayidle font-roboto" ;;
    emerge) echo "app-shells/fish app-misc/jq gui-apps/alacritty dev-lang/python dev-python/pillow gui-apps/wl-clipboard gnome-extra/zenity x11-libs/libnotify net-misc/networkmanager media-video/pipewire media-video/wireplumber app-misc/brightnessctl sys-apps/power-profiles-daemon sys-power/upower sys-auth/polkit sys-auth/mate-polkit sys-apps/xdg-desktop-portal sys-apps/xdg-desktop-portal-gtk media-libs/fontconfig net-misc/curl app-arch/unzip app-arch/tar x11-misc/gammastep gui-apps/swayidle media-fonts/roboto media-fonts/jetbrains-mono" ;;
    *)      echo "" ;;
  esac
}

AUR=''
detect_aur() { for h in paru yay; do command -v "$h" >/dev/null 2>&1 && { AUR=$h; return; }; done; }

# =========================================================================
#  steps
# =========================================================================
install_packages() {
  say "System packages"
  detect_pm
  if [ "$DO_PACKAGES" = 0 ]; then warn "skipped (--no-packages)"; return; fi
  if [ "$PM" = unknown ]; then
    warn "no supported package manager found — install these yourself, then re-run with --no-packages:"
    info "alacritty python3(+Pillow) wl-clipboard zenity libnotify NetworkManager pipewire wireplumber"
    info "brightnessctl power-profiles-daemon upower polkit(+agent) xdg-desktop-portal(-gtk) fontconfig"
    info "optional: gammastep swayidle"
    return
  fi
  info "package manager: ${B}$PM${RST}"
  [ "$PM" = apt ] && $SUDO apt-get update -qq || true
  # shellcheck disable=SC2086
  $PM_INSTALL $(pkg_list) || warn "some packages failed — that's often fine, continuing."
  ok "base packages done"
}

install_quickshell() {
  say "quickshell"
  if command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1; then ok "already installed"; return; fi
  [ "$DO_PACKAGES" = 0 ] && { warn "not installed and --no-packages set — see https://quickshell.outfoxxed.me/docs/"; return; }
  case "$PM" in
    pacman)
      detect_aur
      if [ -n "$AUR" ]; then $AUR -S --needed --noconfirm quickshell || warn "AUR build failed"
      else warn "install an AUR helper (paru/yay) then: paru -S quickshell"; fi ;;
    dnf)
      $SUDO dnf copr enable -y errornointernet/quickshell && $SUDO dnf install -y quickshell || warn "COPR install failed" ;;
    zypper)
      warn "openSUSE: add the OBS repo — https://software.opensuse.org/package/quickshell — then: zypper in quickshell" ;;
    apt)
      warn "Debian/Ubuntu have no quickshell package. Build it: https://quickshell.outfoxxed.me/docs/guide/install/" ;;
    *)
      warn "no known quickshell package for '$PM'. Build from source: https://quickshell.outfoxxed.me/docs/" ;;
  esac
  command -v qs >/dev/null 2>&1 && ok "installed" || warn "quickshell still missing — the shell won't start until it's there."
}

install_niri() {
  say "niri"
  if command -v niri >/dev/null 2>&1; then ok "already installed"; return; fi
  [ "$DO_PACKAGES" = 0 ] && { warn "not installed and --no-packages set — https://github.com/YaLTeR/niri/wiki/Getting-Started"; return; }
  case "$PM" in
    pacman) $PM_INSTALL niri || warn "pacman: niri not found (needs [extra])" ;;
    dnf)    $SUDO dnf copr enable -y yalter/niri && $SUDO dnf install -y niri || warn "COPR install failed" ;;
    apt)    $PM_INSTALL niri || warn "apt: niri needs Debian 13+/Ubuntu 24.10+ — else build from source" ;;
    zypper) $PM_INSTALL niri || warn "zypper: niri is in Tumbleweed/Factory" ;;
    xbps)   $PM_INSTALL niri || warn "xbps: niri not found" ;;
    *)      warn "no known niri package for '$PM' — https://github.com/YaLTeR/niri/wiki/Getting-Started" ;;
  esac
  command -v niri >/dev/null 2>&1 && ok "installed" || warn "niri still missing."
}

install_matugen() {
  say "matugen"
  if command -v matugen >/dev/null 2>&1 || [ -x "$BIN_DIR/matugen" ]; then ok "already installed"; return; fi
  [ "$DO_PACKAGES" = 0 ] && { warn "not installed and --no-packages set — dynamic wallpaper colours will fall back to a plain palette."; return; }
  if [ "$PM" = pacman ]; then
    detect_aur
    [ -n "$AUR" ] && { $AUR -S --needed --noconfirm matugen-bin || $AUR -S --needed --noconfirm matugen || true; }
  fi
  if ! command -v matugen >/dev/null 2>&1; then
    if command -v cargo >/dev/null 2>&1; then
      info "building with cargo (this takes a minute)…"
      cargo install matugen --locked || warn "cargo install matugen failed"
      [ -x "$HOME/.cargo/bin/matugen" ] && { mkdir -p "$BIN_DIR"; ln -sf "$HOME/.cargo/bin/matugen" "$BIN_DIR/matugen"; }
    else
      warn "matugen not packaged here and no cargo. Get a binary from https://github.com/InioX/matugen/releases and drop it in $BIN_DIR."
    fi
  fi
  command -v matugen >/dev/null 2>&1 || [ -x "$BIN_DIR/matugen" ] && ok "installed" || warn "matugen missing — curated colour schemes still work; 'Dynamic' mode won't."
}

install_shell() {
  say "Shell  →  $SHELL_DST"
  mkdir -p "$(dirname "$SHELL_DST")" "$BIN_DIR"
  if [ -e "$SHELL_DST" ] || [ -L "$SHELL_DST" ]; then
    if [ -e "$SHELL_DST/.materiality" ]; then
      info "replacing a previous Materiality install"
    else
      local bak="$SHELL_DST.bak.$(date +%s)"
      warn "existing config moved to $bak"
      mv "$SHELL_DST" "$bak"
    fi
  fi
  rm -rf "$SHELL_DST"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude='__pycache__/' --exclude='*.pyc' "$REPO_DIR/shell/" "$SHELL_DST/"
  else
    mkdir -p "$SHELL_DST"; cp -a "$REPO_DIR/shell/." "$SHELL_DST/"
    find "$SHELL_DST" -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true
  fi
  printf 'installed by materiality-shell/install.sh on %s\n' "$(date)" > "$SHELL_DST/.materiality"
  ok "copied $(find "$SHELL_DST" -type f | wc -l) files"

  say "Helper scripts  →  $BIN_DIR"
  local n=0
  for s in "$SHELL_DST"/scripts/expressive-*; do
    [ -f "$s" ] || continue
    chmod +x "$s"
    ln -sf "$s" "$BIN_DIR/$(basename "$s")"
    n=$((n+1))
  done
  chmod +x "$SHELL_DST"/scripts/* 2>/dev/null || true
  ok "linked $n scripts (expressive-theme, -wall, -niri, -settings, …)"
  case ":$PATH:" in
    *":$BIN_DIR:"*) : ;;
    *) warn "$BIN_DIR is not on your \$PATH — add it in your shell rc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
  esac
}

setup_dirs() {
  say "State directories"
  mkdir -p "$STATE_DIR" "$DATA_DIR/wallpapers"
  ok "$STATE_DIR  and  $DATA_DIR/wallpapers"
}

# Copy the fish config into place. Shared shape with update.sh.
deploy_fish_config() {
  local fdst="$XDG_CONFIG_HOME/fish"
  mkdir -p "$fdst/conf.d" "$fdst/functions"
  if [ -f "$fdst/config.fish" ] && ! head -1 "$fdst/config.fish" | grep -q 'expressive.*fish shell config'; then
    cp "$fdst/config.fish" "$fdst/config.fish.bak.$(date +%s)"
    warn "your existing config.fish was backed up"
  fi
  cp -f "$REPO_DIR/fish/config.fish" "$fdst/config.fish"
  cp -f "$REPO_DIR"/fish/conf.d/*.fish "$fdst/conf.d/"
  cp -f "$REPO_DIR"/fish/functions/*.fish "$fdst/functions/"
}

setup_fish() {
  say "Fish shell  →  $XDG_CONFIG_HOME/fish"
  if ! command -v fish >/dev/null 2>&1; then
    warn "fish isn't installed — install it and re-run to get the prompt + login shell."
    return
  fi
  local fishbin; fishbin="$(command -v fish)"

  deploy_fish_config
  ok "prompt (kaomoji · clock · cmd/session timers) + palette colours installed"
  command -v jq >/dev/null 2>&1 || warn "jq missing — the prompt won't pick up the Material You colours until it's installed."

  # fish must be a known shell before chsh will take it
  if ! grep -qxF "$fishbin" /etc/shells 2>/dev/null; then
    if [ -n "$SUDO" ] && echo "$fishbin" | $SUDO tee -a /etc/shells >/dev/null 2>&1; then
      ok "registered $fishbin in /etc/shells"
    else
      warn "add '$fishbin' to /etc/shells (needs root) for chsh to accept it"
    fi
  fi

  if [ "$DO_SHELL" = 0 ]; then
    info "login shell left as $(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7 || echo "${SHELL:-/bin/sh}")  (--no-shell)"
    info "run later:  chsh -s $fishbin"
    return
  fi

  local cur; cur="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
  if [ "$cur" = "$fishbin" ]; then
    ok "login shell already $fishbin"
  elif ask "make fish your login shell now? (chsh will ask for your password)"; then
    if chsh -s "$fishbin" 2>/dev/null || { [ -n "$SUDO" ] && $SUDO chsh -s "$fishbin" "$(id -un)" 2>/dev/null; }; then
      ok "login shell → $fishbin   (new terminals / next login)"
    else
      warn "chsh didn't go through — run it yourself:  chsh -s $fishbin"
    fi
  else
    info "skipped; run 'chsh -s $fishbin' whenever you want it"
  fi
}

dl() {  # dl <url> <dest>   — quiet, follows redirects, fails loudly
  curl -fsSL --retry 2 --connect-timeout 20 -o "$2" "$1"
}

have_font() { command -v fc-list >/dev/null 2>&1 && fc-list 2>/dev/null | grep -qi "$1"; }

install_fonts() {
  say "Fonts  →  $FONT_DIR"
  if [ "$DO_FONTS" = 0 ]; then warn "skipped (--no-fonts)"; return; fi
  mkdir -p "$FONT_DIR"
  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "${tmp:-/nonexistent}"' RETURN

  # Material Symbols Rounded — never packaged, always fetched. This is the one
  # the shell can't do without (every icon is a ligature from it).
  if have_font "Material Symbols Rounded"; then
    ok "Material Symbols Rounded (already present)"
  elif dl "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" "$FONT_DIR/MaterialSymbolsRounded.ttf"; then
    ok "Material Symbols Rounded"
  else
    warn "Material Symbols Rounded download failed — icons will render as boxes."
    warn "grab it from https://github.com/google/material-design-icons/tree/master/variablefont and drop the .ttf in $FONT_DIR"
  fi

  # Roboto — from the distro if the package landed, else download.
  if have_font "Roboto" && ! have_font "Roboto Mono"; then :; fi
  if have_font "Roboto"; then
    ok "Roboto (from packages)"
  else
    dl "https://github.com/google/fonts/raw/main/ofl/roboto/Roboto%5Bwdth%2Cwght%5D.ttf" "$FONT_DIR/Roboto.ttf" \
      && dl "https://github.com/google/fonts/raw/main/ofl/roboto/Roboto-Italic%5Bwdth%2Cwght%5D.ttf" "$FONT_DIR/Roboto-Italic.ttf" \
      && ok "Roboto" || warn "Roboto download failed — install your distro's roboto font package."
  fi
  if have_font "Roboto Mono"; then
    ok "Roboto Mono (from packages)"
  else
    dl "https://github.com/google/fonts/raw/main/ofl/robotomono/RobotoMono%5Bwght%5D.ttf" "$FONT_DIR/RobotoMono.ttf" \
      && ok "Roboto Mono" || warn "Roboto Mono download failed — a system mono is used instead."
  fi

  # JetBrains Mono — clock + terminal. Package or release zip.
  if have_font "JetBrains Mono"; then
    ok "JetBrains Mono (from packages)"
  elif dl "https://github.com/JetBrains/JetBrainsMono/releases/download/v$JBMONO_VER/JetBrainsMono-$JBMONO_VER.zip" "$tmp/jb.zip" \
       && unzip -oq "$tmp/jb.zip" -d "$tmp/jb"; then
    mkdir -p "$FONT_DIR/JetBrainsMono"
    find "$tmp/jb" -iname 'JetBrainsMono-*.ttf' -exec cp -f {} "$FONT_DIR/JetBrainsMono/" \;
    ok "JetBrains Mono $JBMONO_VER"
  else
    warn "JetBrains Mono unavailable — the clock falls back to Roboto Mono."
  fi

  command -v fc-cache >/dev/null 2>&1 && { fc-cache -f "$FONT_DIR" >/dev/null 2>&1; ok "font cache rebuilt"; }
}

install_cursor() {
  say "Cursor  ($CURSOR_NAME)"
  if [ "$DO_CURSOR" = 0 ]; then warn "skipped (--no-cursor)"; return; fi
  mkdir -p "$ICON_DIR"
  if [ -d "$ICON_DIR/$CURSOR_NAME" ]; then
    ok "already present"
  else
    local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "${tmp:-/nonexistent}"' RETURN
    if dl "https://github.com/ful1e5/Bibata_Cursor/releases/download/v$CURSOR_VER/$CURSOR_NAME.tar.xz" "$tmp/c.tar.xz" \
       && tar -xJf "$tmp/c.tar.xz" -C "$ICON_DIR"; then
      ok "installed to $ICON_DIR/$CURSOR_NAME"
    else
      warn "cursor download failed — install any cursor theme and set it in niri's cursor {} block."
      return
    fi
  fi
  # make it the default for GTK/Xcursor apps
  mkdir -p "$HOME/.icons/default"
  cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=$CURSOR_NAME
EOF
  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_NAME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
  fi
  ok "set as default cursor (size $CURSOR_SIZE)"
}

setup_niri() {
  say "niri config"
  local dst="$XDG_CONFIG_HOME/niri/config.kdl"
  mkdir -p "$XDG_CONFIG_HOME/niri"
  if [ "$DO_NIRI" = 1 ]; then
    [ -e "$dst" ] && { mv "$dst" "$dst.bak.$(date +%s)"; warn "your niri config was backed up next to it."; }
    cp "$REPO_DIR/niri/config.kdl" "$dst"
    ok "installed niri/config.kdl (edit outputs/keys to taste)"
  elif [ ! -e "$dst" ]; then
    cp "$REPO_DIR/niri/config.kdl" "$dst"
    ok "no niri config existed — installed the example one"
  else
    warn "you already have a niri config; not touching it. Add these lines yourself:"
    cat <<EOF
   ${DIM}spawn-at-startup "qs" "-c" "$CONF_ID"
   cursor { xcursor-theme "$CURSOR_NAME"; xcursor-size $CURSOR_SIZE; }
   binds {
       Mod+Space { spawn "qs" "-c" "$CONF_ID" "ipc" "call" "launcher" "toggle"; }
       Mod+A     { spawn "qs" "-c" "$CONF_ID" "ipc" "call" "controlCenter" "toggle"; }
       Mod+Ctrl+Comma { spawn "expressive-settings"; }
       Super+Alt+L    { spawn "qs" "-c" "$CONF_ID" "ipc" "call" "lock" "lock"; }
   }${RST}
   full reference: $REPO_DIR/niri/config.kdl
EOF
  fi
}

summary() {
  echo
  say "${GRN}Done.${RST}"
  cat <<EOF
   Start it now without logging out:   ${B}qs -c $CONF_ID &${RST}
   Or just start a niri session — it autostarts from spawn-at-startup.

   Open settings:   ${B}expressive-settings${RST}   (or Mod+Ctrl+,)
   Pick a wallpaper there — it seeds the whole Material You palette.

   Fish is now your login shell (kaomoji prompt, clock, cmd/session timers,
   palette-aware colours) — open a new terminal to see it.

   Missing something? Re-run this script; it's idempotent.
   Remove everything:   ${B}./uninstall.sh${RST}
EOF
  for c in qs niri; do
    command -v "$c" >/dev/null 2>&1 || warn "$c is still not installed — see the notes above."
  done
}

# =========================================================================
main() {
  echo "${B}Materiality${RST}${DIM} — installer${RST}"
  echo "${DIM}repo: $REPO_DIR${RST}"
  echo
  install_packages
  install_quickshell
  install_niri
  install_matugen
  install_shell
  setup_dirs
  install_fonts
  install_cursor
  setup_fish
  setup_niri
  summary
}
main
