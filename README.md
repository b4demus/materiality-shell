# Materiality

A Material 3 Expressive desktop shell for **[Quickshell]** and the **[niri]**
scrollable-tiling compositor — floating segmented bar, quick settings, OSD,
notifications, an app launcher, a lock screen, and a full **settings app** that
configures the shell *and* niri underneath it. Dynamic Material You colour from
your wallpaper, spring motion, pill shapes.

*vibed by b4demus*

```sh
git clone https://github.com/b4demus/materiality-shell.git
cd materiality-shell
./install.sh
```

The installer is idempotent and cross-distro: it detects your package manager
(pacman / dnf / apt / zypper / xbps / apk / emerge), installs what it can,
downloads the fonts and the cursor, drops the shell into
`~/.config/quickshell/expressive/`, symlinks the helper scripts into
`~/.local/bin/`, deploys the fish config and makes fish your login shell, and
installs an example niri config if you don't have one. Anything it can't do it
prints in plain words. `--no-shell` keeps your current login shell.

Then either start a niri session (it autostarts) or, from inside one:

```sh
qs -c expressive &
expressive-settings          # or  Mod+Ctrl+,
```

---

## Dependencies

### Required — the shell needs these to run

| What | Command / package | Notes |
|---|---|---|
| **Quickshell** | `qs` | the runtime. Not in every distro yet — see below. |
| **niri** | `niri` | the compositor Materiality is built for. |
| **Qt 6** | (pulled in by Quickshell) | Qt Quick + Qt Shader Tools. |
| **Python 3** | `python3` | the theme / niri / night-light / idle helper scripts. |
| **fontconfig** | `fc-cache`, `fc-list` | font registration. |
| **fish** | `fish` | the shell it installs and sets as your login shell (`--no-shell` to skip). |
| Fonts | Roboto, Roboto Mono, **Material Symbols Rounded**, JetBrains Mono | the installer fetches these; Material Symbols is the one it truly can't run without (every icon is a ligature from it). |

### Required for full function — installed by default, degrade gracefully if missing

| Feature | Needs | Without it |
|---|---|---|
| Wallpaper → palette (Dynamic mode) | **matugen**, **python3-pillow** | curated colour schemes still work; "Dynamic" falls back to a plain seed palette. |
| Terminal | **alacritty** | the bar's terminal bind does nothing; theming still writes `~/.config/alacritty/`. |
| Volume / mic / media | **pipewire**, **wireplumber** (`wpctl`) | status island shows no audio, volume OSD dead. |
| Networking tile | **NetworkManager** (`nmcli`) | Wi-Fi page and tile are empty. |
| Bluetooth tile | **bluez** (`bluetoothctl`) | Bluetooth page and tile are empty. |
| Brightness | **brightnessctl** | brightness slider / OSD dead on laptops. |
| Battery / power profiles | **upower**, **power-profiles-daemon** | battery chip and power page blank. |
| Clipboard history chip | **wl-clipboard** (`wl-paste`) | the clipboard chip stays empty. |
| Wallpaper file picker | **zenity** (or `kdialog`) | "Browse…" in the wallpaper picker does nothing. |
| Notifications from apps | **libnotify** server is provided by the shell | timer/alarm `notify-send` needs `libnotify` installed. |
| Privilege prompts | a **polkit** authentication agent (`mate-polkit` / `polkit-gnome`) | actions that need root can't prompt. |
| Screenshots / portals | **xdg-desktop-portal** + **xdg-desktop-portal-gtk** | niri screenshot portal, file dialogs. |
| Palette-aware fish prompt | **jq** | the fish prompt colours fall back to plain ANSI without it. |

### Optional

| Feature | Needs |
|---|---|
| Night light / colour temperature | **gammastep** (or `wlsunset`) |
| Idle blank / lock-on-idle / suspend-on-idle | **swayidle** |
| Palette-tinted `cmatrix` wrapper (`shell/scripts/cmatrix`) | **cmatrix** |

### The three that aren't packaged everywhere

**Quickshell**, **niri** and **matugen** are young projects. The installer
handles them per-distro:

| Distro | Quickshell | niri | matugen |
|---|---|---|---|
| **Arch** | AUR (`paru -S quickshell`) | `pacman -S niri` | AUR (`matugen-bin`) |
| **Fedora** | COPR `errornointernet/quickshell` | COPR `yalter/niri` | `cargo install matugen` |
| **openSUSE TW** | OBS repo (manual) | `zypper in niri` | `cargo install matugen` |
| **Debian 13+ / Ubuntu 24.10+** | build from [source][qs-install] | `apt install niri` | prebuilt binary / `cargo` |
| **Void** | build from source | `xbps-install niri` | `cargo install matugen` |
| everything else | [Quickshell docs][qs-install] | [niri wiki][niri-install] | [matugen releases][matugen-rel] |

If a package step fails the installer says so and keeps going — you can install
that one piece by hand and re-run `./install.sh`.

---

## What the installer touches

Nothing outside your home except system packages (via `sudo` + your package
manager). Specifically:

```
~/.config/quickshell/expressive/     the shell (copied from ./shell/)
~/.local/bin/expressive-*             symlinks to shell/scripts/*
~/.config/fish/                       config.fish + conf.d/ + functions/  (from ./fish/)
~/.local/share/fonts/                 Roboto, Roboto Mono, Material Symbols, JetBrains Mono
~/.local/share/icons/Bibata-Modern-Classic/   the cursor
~/.icons/default/index.theme          makes Bibata the default cursor
~/.local/state/expressive/            palette, settings.json, alarms, clipboard, … (created empty)
~/.local/share/expressive/wallpapers/ your wallpaper catalogue (created empty)
~/.config/niri/config.kdl             only if you have none, or pass --niri
```

It also runs **`chsh -s $(command -v fish)`** to make fish your login shell
(prompt for your password; skip with `--no-shell`), and adds fish to
`/etc/shells` if missing. `gsettings` cursor keys are set if `gsettings`
exists. An existing shell config or `config.fish` is moved aside to
`…bak.<timestamp>` before copying.

### Installer flags

```
./install.sh --no-packages     don't call the package manager (deps handled by you)
             --no-fonts        skip the font download
             --no-cursor       skip the Bibata download
             --no-shell        install the fish config but keep your current login shell
             --niri            install niri/config.kdl, backing up any existing one
             -y                answer yes to everything
./update.sh   [--restart]      pull + redeploy an installed copy (see below)
./uninstall.sh [--purge]       remove the shell + symlinks (--purge also drops state)
```

---

## niri integration

`shell/scripts/expressive-niri` is a *surgical* KDL editor: it rewrites only the
values it owns and leaves your comments and hand-written blocks alone. The
settings app uses it to apply gaps, borders, focus-ring width, corner radius,
input and keybinds live. The bits it manages are marked in your config:

```kdl
spawn-at-startup "qs" "-c" "expressive"

layout {
    focus-ring {
        // === expressive:colors — managed by ~/.local/bin/expressive-wall ===
        active-color   "#…"   // rewritten from the Material You palette
        inactive-color "#…"
        urgent-color   "#…"
        // === /expressive:colors ===
    }
}

// === expressive:corner — managed by the settings app ===
window-rule { geometry-corner-radius 16; clip-to-geometry true; }
// === /expressive:corner ===

cursor { xcursor-theme "Bibata-Modern-Classic"; xcursor-size 24; }
environment { QT_QPA_PLATFORMTHEME "gtk3"; }   // Qt follows the GTK/M3 palette
```

The full working example is [`niri/config.kdl`](niri/config.kdl). If you already
run niri, the installer won't overwrite your config — it prints the snippet to
paste. `niri validate` is run on every write.

---

## Keybinds (from the example config)

| Key | Action |
|---|---|
| `Mod+Return` | terminal (alacritty) |
| `Mod+Space` | app launcher |
| `Mod+A` | control center / quick settings |
| `Mod+I` · `Mod+Ctrl+,` | settings app |
| `Super+Alt+L` | lock screen |
| `Mod+Shift+S` · `Print` | region screenshot (lands in the clipboard chip) |
| `Mod+Q` / `Mod+D` / `Mod+F` / `F11` | close / float / maximize / fullscreen |
| `XF86Audio*` / `XF86MonBrightness*` | volume, mute, brightness (via `wpctl` / `brightnessctl`) |

---

## Shell (fish)

The installer sets **fish** as your login shell and drops a config in
`~/.config/fish/` that matches the desktop:

* **Two-line prompt** — `path  ⎇git` then `<kaomoji> HH:MM:SS ❯`. Arrow and
  kaomoji go green on success, red on failure; the path colour is the live
  `primary` from the Material You palette.
* **Right prompt** — `⏱ <last cmd duration>` (when > 1.5 s) · `⧗ <session uptime>`.
* **`fish_greeting`** off; a random kaomoji + date/host instead.
* **Long-command notifier** — `notify-send` with a kaomoji when a command runs
  longer than 45 s, so it shows up as one of the shell's own notification cards.
* **`conf.d/00-expressive-colors.fish`** reads `~/.local/state/expressive/colors.json`
  with `jq` on every new shell, so `e_primary` / `e_secondary` / … track whatever
  scheme is active. (Needs `jq`; the 16 ANSI colours are already themed by
  `expressive-theme`.)

Keep bash? `./install.sh --no-shell` installs the config but leaves your login
shell alone — run `chsh -s $(command -v fish)` later, or point just your
terminal at `~/.local/bin/expressive-shell` (execs fish, falls back to bash).
`./update.sh` refreshes the fish files but never changes your login shell.

---

## Updating an installed copy

From the same clone you installed from:

```sh
cd materiality-shell
./update.sh
```

It `git pull`s, re-deploys `shell/` into `~/.config/quickshell/expressive/`
**in place**, refreshes the `~/.local/bin/expressive-*` symlinks (adding new
scripts, dropping removed ones) and nudges the running shell to hot-reload.
Your settings, palette, wallpaper catalogue and niri config are never
touched — they live in `~/.local/state/expressive/` and `~/.config/niri/`.

| Flag | |
|---|---|
| `--restart` | full `qs kill` + relaunch instead of hot-reload. Use it when an update changes a **keybind or adds an IPC handler** — Quickshell's hot-reload doesn't pick those up. |
| `--no-pull` | deploy the current checkout without fetching. |
| `--fonts` | also re-run the font + cursor step. |

Lost the clone, or installed by hand? Re-clone and run `./install.sh` again —
it's idempotent and detects the previous install (no `.bak` churn):

```sh
git clone https://github.com/b4demus/materiality-shell.git
cd materiality-shell && ./install.sh --no-packages
```

Doing it fully manually is just: `cp -a shell/. ~/.config/quickshell/expressive/`
then `touch ~/.config/quickshell/expressive/shell.qml` (or relogin).

---

## Layout of this repo

```
install.sh                     the cross-distro installer
update.sh                      pull + redeploy an installed copy
uninstall.sh                   remove it (--purge also drops state)
shell/                         the Quickshell config → ~/.config/quickshell/expressive/
  shell.qml  config/  components/  services/  modules/  theme/  scripts/
fish/                          the fish config → ~/.config/fish/
niri/config.kdl                a complete example niri config with Materiality wired in
docs/ARCHITECTURE.md           how the shell is put together (config store, managers, niri editor)
docs/DEPENDENCIES.md           the dependency table again, with the "why" for each
```

## Notes

* The Quickshell config id is **`expressive`** (`qs -c expressive`) — that's the
  historical internal name; the shell is branded *Materiality* everywhere you see it.
* Everything installs under `$HOME`. No system files are modified beyond package
  installation.
* Tested on niri 25.x/26.x. `niri msg --json` has no `is_fullscreen` field on some
  versions — the shell infers it.

## License

MIT — see [LICENSE](LICENSE). Bundled fonts and the Bibata cursor are downloaded
at install time and keep their own licenses (Apache-2.0 / OFL / SIL).

[Quickshell]: https://quickshell.outfoxxed.me/
[niri]: https://github.com/YaLTeR/niri
[qs-install]: https://quickshell.outfoxxed.me/docs/guide/install/
[niri-install]: https://github.com/YaLTeR/niri/wiki/Getting-Started
[matugen-rel]: https://github.com/InioX/matugen/releases
