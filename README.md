# Stradi Themes

Dark **Stradisymphony** theme collection for [Omarchy](https://omarchy.org/), the [Falkon](https://www.falkon.org/) browser, and **Bash** (agnoster prompt).

| What | Where it lands |
|------|----------------|
| Omarchy theme | `~/.config/omarchy/themes/stradisymphony/` |
| Falkon theme | `~/.local/share/falkon/themes/stradisymphony/` |
| Falkon active theme setting | `activeTheme` under `[Themes]` in `~/.config/falkon/profiles/<profile>/settings.ini` |
| Bash agnoster theme | `~/.config/stradi/bash/agnoster.sh` → sourced from `~/.bashrc` |

Palette:

- background `#020202`, lighter `#1b1b1b`, foreground `#C3C9CD`, muted `#92979a`
- accent `#8171b3`, selection `#1b1b1b`
- icon theme: `Yaru-purple`

## Contents

```
.
├── install.sh                     # unattended installer (recommended)
├── README.md
├── omarchy/
│   └── stradisymphony/            # Omarchy theme: colors.toml, icons.theme,
│       ├── colors.toml              preview.png, backgrounds/<wallpaper>.png
│       ├── icons.theme
│       ├── preview.png
│       └── backgrounds/
│           └── Gemini_Generated_Image_.png
├── falkon/
│   └── stradisymphony/            # Falkon QSS theme: main.css, metadata.desktop,
│       ├── main.css                 theme.png, images/*.svg (muted monochrome)
│       ├── metadata.desktop
│       ├── theme.png
│       └── images/
└── bash/
    └── stradisymphony/            # Bash agnoster theme: agnoster.sh (truecolor,
        ├── agnoster.sh              Omarchy colors.toml-aware), bashrc.example
        ├── bashrc.example
        └── bashrc.minimal.example
```

## Agent / unattended install

Run from a clone of this repository:

```bash
git clone https://github.com/gbenselum/stradi_themes.git
cd stradi_themes
./install.sh --launch
```

`install.sh` is fully non-interactive:

1. **Omarchy theme** – copies the theme into `~/.config/omarchy/themes/` and runs `omarchy theme set stradisymphony` (skipped if the `omarchy` CLI or `--skip-apply` is given).
2. **Falkon theme** – copies the QSS theme into `~/.local/share/falkon/themes/`.
3. **Falkon active theme** – if a Falkon instance is running it is closed first (otherwise it would overwrite the setting on exit), then `activeTheme=stradisymphony` is written under `[Themes]` in the profile's `settings.ini` (the active profile is read from `profiles.ini`, defaulting to `default`).
4. **Bash agnoster theme** – copies `bash/stradisymphony/agnoster.sh` → `~/.config/stradi/bash/agnoster.sh`, backs up `~/.bashrc` and appends `source ~/.config/stradi/bash/agnoster.sh` (disables `starship` prompt, requires Powerline/Nerd Font).

Options:

```bash
./install.sh              # install everything, do not launch Falkon
./install.sh --launch     # also launch Falkon at the end
./install.sh --omarchy    # only the Omarchy theme
./install.sh --falkon     # only the Falkon theme
./install.sh --bash       # only the Bash agnoster theme
./install.sh --skip-apply # copy files but do not run `omarchy theme set`
```

Exit codes: `0` success, `2` bad argument, any other code = failure (script stops on first error with `set -e`).

### Manual install (fallback)

**Omarchy theme:**

```bash
mkdir -p ~/.config/omarchy/themes/stradisymphony
cp -a omarchy/stradisymphony/. ~/.config/omarchy/themes/stradisymphony/
omarchy theme set stradisymphony
```

**Falkon theme:**

```bash
# close Falkon first so it can't overwrite settings on exit
pkill -x falkon || true
mkdir -p ~/.local/share/falkon/themes/stradisymphony
cp -a falkon/stradisymphony/. ~/.local/share/falkon/themes/stradisymphony/
```

Then add, in `~/.config/falkon/profiles/<profile>/settings.ini` (create the profile dir if it doesn't exist):

```ini
[Themes]
activeTheme=stradisymphony
```

Relaunch Falkon. The theme appears under *Preferences → Appearance → Theme* as **Stradisymphony**.

**Bash agnoster theme:**

```bash
mkdir -p ~/.config/stradi/bash
cp bash/stradisymphony/agnoster.sh ~/.config/stradi/bash/agnoster.sh
# backup and append to bashrc
cp ~/.bashrc ~/.bashrc.bak-$(date +%Y%m%d-%H%M%S)
grep -q "stradi/bash/agnoster.sh" ~/.bashrc || echo '[[ -f "$HOME/.config/stradi/bash/agnoster.sh" ]] && source "$HOME/.config/stradi/bash/agnoster.sh"' >> ~/.bashrc
source ~/.bashrc
# toggles: agnoster_disable / agnoster_enable / agnoster_reload_theme
```

## Verification

- `omarchy theme current` → `Stradisymphony`
- `~/.local/share/falkon/themes/stradisymphony/main.css` exists
- Profile `settings.ini` contains `[Themes]` → `activeTheme=stradisymphony`
- Falkon UI: near-black chrome (`#020202`) with `#8171b3` accent, muted monochrome toolbar icons

## Notes for agents

- Falkon **must not be running** while `settings.ini` is edited; `install.sh` handles this automatically, manual installs must too.
- The Falkon theme resolves toolbar icons as SVG **fallback** icons (`qproperty-fallbackIcon` only, no `qproperty-themeIcon`). Since `ToolButton::setThemeIcon()` wins over `setFallbackIcon()` when a themed icon exists, never reintroduce `qproperty-themeIcon` if you want the muted icons to stay.
- Omarchy stock themes live under `/usr/share/omarchy/themes` and are **read-only**; user themes must go in `~/.config/omarchy/themes`.
- Hidden files (`.aether-managed`) in the Omarchy theme are intentionally not copied.

## Hyprland keybindings (agent setup)

Add to `~/.config/hypr/bindings.lua` (or append via script) to bind **SUPER + A** → opencode:

```lua
o.bind("SUPER + A", "Opencode", "foot -e /home/gabriel/.local/share/mise/installs/opencode/latest/opencode")
```

Then reload:

```bash
hyprctl reload
```

**Notes:**
- Uses `foot` (default Omarchy terminal) — change to `alacritty`, `kitty`, or `ghostty` if preferred.
- Opencode installed via `mise` — adjust path if installed elsewhere (e.g., `opencode` on PATH).
- The `o` and `hl` globals are available in `bindings.lua` (Omarchy default config loads them).