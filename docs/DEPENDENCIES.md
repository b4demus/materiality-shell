# Dependencies — the long version

`install.sh` installs all of this for you. This file is for when you'd rather do
it by hand, or want to know *why* each thing is there.

## Copy-paste install lines

### Arch / CachyOS / EndeavourOS
```sh
sudo pacman -S --needed niri alacritty python python-pillow wl-clipboard zenity \
  libnotify networkmanager pipewire wireplumber pipewire-pulse brightnessctl \
  power-profiles-daemon upower polkit mate-polkit xdg-desktop-portal \
  xdg-desktop-portal-gtk fontconfig ttf-roboto ttf-roboto-mono ttf-jetbrains-mono \
  gammastep swayidle
paru -S quickshell matugen-bin        # or yay
```

### Fedora
```sh
sudo dnf copr enable errornointernet/quickshell
sudo dnf copr enable yalter/niri
sudo dnf install quickshell niri alacritty python3 python3-pillow wl-clipboard \
  zenity libnotify NetworkManager pipewire wireplumber pipewire-pulseaudio \
  brightnessctl power-profiles-daemon upower polkit mate-polkit \
  xdg-desktop-portal xdg-desktop-portal-gtk fontconfig google-roboto-fonts \
  google-roboto-mono-fonts jetbrains-mono-fonts gammastep swayidle
cargo install matugen --locked        # rustup/cargo needed
```

### Debian 13+ / Ubuntu 24.10+
```sh
sudo apt install niri alacritty python3 python3-pil wl-clipboard zenity \
  libnotify-bin network-manager pipewire wireplumber pipewire-pulse brightnessctl \
  power-profiles-daemon upower policykit-1-gnome xdg-desktop-portal \
  xdg-desktop-portal-gtk fontconfig fonts-roboto fonts-jetbrains-mono \
  gammastep swayidle
# Quickshell: build per https://quickshell.outfoxxed.me/docs/guide/install/
# matugen: prebuilt from https://github.com/InioX/matugen/releases  or  cargo install matugen
```

### openSUSE Tumbleweed
```sh
sudo zypper install niri alacritty python3 python3-Pillow wl-clipboard zenity \
  libnotify-tools NetworkManager pipewire wireplumber pipewire-pulseaudio \
  brightnessctl power-profiles-daemon upower polkit mate-polkit \
  xdg-desktop-portal xdg-desktop-portal-gtk fontconfig google-roboto-fonts \
  jetbrains-mono-fonts gammastep swayidle
# Quickshell: OBS — https://software.opensuse.org/package/quickshell
cargo install matugen --locked
```

### Void
```sh
sudo xbps-install -S niri alacritty python3 python3-Pillow wl-clipboard zenity \
  libnotify NetworkManager pipewire wireplumber brightnessctl \
  power-profiles-daemon upower polkit mate-polkit xdg-desktop-portal \
  xdg-desktop-portal-gtk fontconfig font-roboto-ttf gammastep swayidle
# Quickshell: build from source. matugen: cargo install matugen
```

Then, on any distro:
```sh
git clone https://github.com/b4demus/materiality-shell.git
cd materiality-shell
./install.sh --no-packages        # just the shell, scripts, fonts, cursor, niri config
```

## Fonts

| Font | Why | Source the installer uses |
|---|---|---|
| **Material Symbols Rounded** | every icon in the shell is a ligature glyph from this variable font (`MIcon.qml` drives FILL/wght/GRAD/opsz axes). Nothing renders right without it. | `github.com/google/material-design-icons` (variablefont/) |
| **Roboto** | UI text (`Appearance.fontFamily`). | distro package, else `github.com/google/fonts` |
| **Roboto Mono** | monospace fallback. | distro package, else `github.com/google/fonts` |
| **JetBrains Mono** | the clock, countdowns and calendar numerals (`Appearance.clockFamily`), and Alacritty. | distro package, else JetBrains release zip |

All four live in `~/.local/share/fonts/`. `fc-cache -f` is run after.

## Cursor

**Bibata-Modern-Classic** (size 24), from the
[`ful1e5/Bibata_Cursor`](https://github.com/ful1e5/Bibata_Cursor) releases,
installed to `~/.local/share/icons/`. `~/.icons/default/index.theme` inherits it
so GTK/Xcursor apps pick it up; niri reads it from its own `cursor {}` block.
Swap it for anything else — just keep the two in sync.

## Runtime helpers the scripts call

`expressive-theme` (Python): `matugen`, optionally `PIL`/Pillow for the
wallpaper-colour extraction. `expressive-wall`: `matugen`, `gsettings`.
`expressive-niri`: `niri` (for `niri validate`). `expressive-night`:
`gammastep` or `wlsunset`. `expressive-idle`: `swayidle`, `systemctl`.
`expressive-lock`: `dbus-monitor`, `loginctl`, `flock`. `expressive-clip`:
`wl-paste`, `wl-copy`, `flock`.

PAM for the lock screen uses `/etc/pam.d/swaylock` if present, otherwise it
falls back to the `login` stack — no setup normally needed.
