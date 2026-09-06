# Materiality — a Material 3 Expressive desktop shell for Quickshell + niri

*vibed by b4demus*

A floating segmented bar, quick settings, OSD, notifications, launcher, lock
screen — and a full **settings application** that configures all of it plus the
compositor underneath, styled after **Material You / Material 3 Expressive**
(dynamic colour from the wallpaper, spring motion, pill shapes, large radii).

Built for **niri**: workspaces, outputs, keybinds and layout all come from
niri's own JSON IPC and KDL config, not Hyprland.

## Run

```sh
qs -c expressive
```

niri autostarts it (`~/.config/niri/config.kdl` → `spawn-at-startup "qs" "-c" "expressive"`).

## Settings

```sh
expressive-settings              # open it
expressive-settings wallpaper    # deep-link to a page
```

Also on `Mod+Ctrl+,`, from the gear in quick settings, or over IPC:

```sh
qs -c expressive ipc call settings open
qs -c expressive ipc call settings page nightlight
qs -c expressive ipc call settings get bar.height
qs -c expressive ipc call settings set bar.height 40
```

The window is a real `FloatingWindow`, so it tiles in niri like any other app.
Its navigation adapts to width: expanded list ≥ 1080 px, icon rail ≥ 780 px,
and a dropdown picker below that.

### Pages

| Group | Pages |
|-------|-------|
| Appearance | Theme & colour · Wallpaper · Bar · Motion & density |
| Compositor | Niri · Windows · Workspaces |
| Devices | Displays · Night light · Wi-Fi · Bluetooth · Sound · Keyboard · Mouse & touchpad |
| Behaviour | Shortcuts · Notifications · Power · Applications |
| System | Profiles · Automation · Startup apps · About |

## Architecture

```
shell.qml            root: IPC + per-screen Bar/Background + overlays + settings window
config/              the design system AND the settings store — depends on nothing else
  Settings.qml         SettingsStore: the whole document, val()/set()/patch(), autosaved
  Files.qml            path helpers
  Appearance.qml       M3 tokens (type, shape, spacing, bar geometry) derived from Settings
  Motion.qml           spring presets, scaled by the animation settings
  Colors.qml           M3 colour roles, fed by the palette engine
services/            managers: one per system integration, all importing config/
  NiriConf  Displays  NightLight  Power  Wifi  Net  Bt  Audio  Apps  Privacy
  Shortcuts  Profiles  Wallpaper  Theme  SysInfo  Niri  Bat  Brightness  Bus
  Clipboard  Notifs  TimeTools
components/          M3 Expressive widgets (MCard, MSwitch, MSelect, MSliderRow, …)
modules/settings/    the settings app: SettingsWindow + Page + pages/
modules/bar/         Bar (any screen edge) + BarModule dispatcher + the modules
modules/…            background, osd, notifications, launcher, controlcenter, lock
theme/               matugen template + curated schemes
scripts/             expressive-theme · -wall · -niri · -night · -idle · -lock ·
                     -clip · -privacy · -settings · -shell
```

Two rules keep it untangled:

1. **`config/` imports nothing.** The settings store lives there with the design
   tokens, so tokens can derive from settings without a cycle.
2. **UI never shells out.** Pages talk to managers; managers own the processes.

### How a setting reaches the system

`Settings.set("niri.gapsInner", 12)` reassigns the whole document, so every
binding that read it re-evaluates and `changed`
fires. `NiriConf` hears it, debounces, and writes the KDL. Managers are
instantiated eagerly in `shell.qml` — QML singletons are lazy, and an applier
that only exists while its page is open applies nothing.

## niri integration

`expressive-niri` is a *surgical* KDL editor, not a parse-and-regenerate round
trip — your comments and hand-written blocks survive:

* scalar nodes are rewritten in place, keeping indentation and trailing comments
* flag nodes are toggled by commenting/uncommenting
* an **active** node always wins over a commented-out example above it
* list-ish blocks and shell-owned window rules live between `expressive:` markers
* every write is checked with `niri validate` first, and the previous file is
  kept at `~/.local/state/expressive/niri-config.kdl.bak`

On first run the compositor is authoritative: the store is seeded from your
existing config so the UI opens showing your real desktop. After that the store
leads. niri hot-reloads, so gaps, borders, input and rules apply immediately.

```sh
expressive-niri get                 # the managed values as JSON
expressive-niri binds               # keybinds as JSON
expressive-niri validate
```

## Dynamic colour

```sh
expressive-wall ~/Pictures/some-wallpaper.png
```

Sets the wallpaper and regenerates the Material You palette with `matugen` into
`~/.local/state/expressive/colors.json`, which the shell watches. It also
recolours niri's focus ring, Alacritty and GTK from the same palette.

Three sources, chosen on the Theme & colour page:

* **Dynamic** — the seed is the wallpaper's defining colour
* **Auto** — the curated scheme closest to the wallpaper
* **A scheme, or a hand-picked accent** — `expressive-theme accent:#3f7fd0`,
  which is what "colours from wallpaper: off" uses

## Optional backends

Two features need a helper the shell can't provide itself. Both detect it and
say exactly what to install instead of pretending to work:

| Feature | Needs | Why |
|---------|-------|-----|
| Night light | `gammastep` (or `wlsunset`) | real wlr-gamma-control ramps, not a UI overlay |
| Idle blank / lock / suspend | `swayidle` | niri has no idle section and this Quickshell has no idle binding |

```sh
sudo dnf install gammastep swayidle
```

## Profiles & automation

A profile is a flat patch of settings paths. Applying one is a single
`Settings.patch()`, so every manager reacts exactly as if you had flipped each
switch by hand. Rules can apply a profile when an app is running, a display is
connected, you are on battery, a Bluetooth device connects, or at a time of day.

## Dependencies

- `quickshell` 0.2.x, `niri`, `matugen`
- Fonts: **Roboto**, **Roboto Mono**, **Material Symbols Rounded** (variable),
  **JetBrains Mono**
- `nmcli` (network), PipeWire (audio), UPower + power-profiles-daemon (power),
  `zenity` (file picker). Optional: `gammastep`, `swayidle`, `brightnessctl`

## Gotcha: `on*` colour roles

QML parses a property literally named `onSurface` as a signal handler, so the
"on-" M3 roles live under a nested object: `Colors.on.surface`,
`Colors.on.primary`, `Colors.on.secondaryContainer`.
