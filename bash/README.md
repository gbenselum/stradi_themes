# Bash — Stradisymphony Agnoster Theme

Bash port of the zsh `agnoster` theme, theme-aware for Omarchy. Powerline segments (``, ``) with 24-bit truecolor from `colors.toml`, adapts to light/dark.

| Segment | Color (theme) | Shows |
|---------|---------------|-------|
| `status` | `red` (`#b07fb1` dark / `#D14D41` light) | `✘` exit code, `⚡` root, `⚙` jobs |
| `context` | `lighter_background` + `foreground` | `user@host` only for SSH/root |
| `virtualenv` | `magenta` | ` venv` / `conda` |
| `dir` | `blue` (`#8171b3`) | `~`-contracted path, shortened if deep |
| `git` | `green` clean / `yellow` dirty | ` branch*` + `↑/↓/↕` |
| prompt | `green` ok / `red` err | `❯` |

Requires a Powerline/Nerd Font (Omarchy ships JetBrainsMono Nerd Font).

## Files

```
bash/stradisymphony/
├── agnoster.sh              # standalone theme — source it from ~/.bashrc
├── bashrc.example           # full ~/.bashrc backup from author (with inlined theme)
└── bashrc.minimal.example   # minimal snippet to source agnoster.sh
```

## Quick install

```bash
git clone https://github.com/gbenselum/stradi_themes.git
cd stradi_themes
./install.sh --bash          # installs bash theme
# or everything:
./install.sh                 # omarchy + falkon + bash
```

`--bash` does:
1. Copies `bash/stradisymphony/agnoster.sh` → `~/.config/stradi/bash/agnoster.sh`
2. Backs up `~/.bashrc` → `~/.bashrc.bak-<timestamp>` (if not already backed up)
3. Appends `source ~/.config/stradi/bash/agnoster.sh` to `~/.bashrc` if not present
4. Disables `starship` prompt (Omarchy default) in favor of agnoster

Verification:
```bash
source ~/.bashrc
echo $AGNOSTER_DIR_BG  # → #8171b3 (Stradisymphony)
agnoster_reload_theme  # after `omarchy theme set <name>`
```

## Manual install

```bash
# 1. Copy theme
mkdir -p ~/.config/stradi/bash
cp bash/stradisymphony/agnoster.sh ~/.config/stradi/bash/agnoster.sh

# 2. Source it AFTER Omarchy rc in ~/.bashrc
cat >> ~/.bashrc <<'EOF'

# Stradisymphony Agnoster Bash Theme
[[ -f "$HOME/.config/stradi/bash/agnoster.sh" ]] && source "$HOME/.config/stradi/bash/agnoster.sh"
EOF

source ~/.bashrc
```

Or directly source from repo without copying:
```bash
echo 'source "$HOME/Projects/stradi_themes/bash/stradisymphony/agnoster.sh"' >> ~/.bashrc
```

## Toggles

```bash
agnoster_disable        # simple \u@\h \w prompt
agnoster_enable         # re-enable
agnoster_reload_theme   # re-parse colors.toml after `omarchy theme set`
```

To fully revert:
```bash
cp ~/.bashrc.bak ~/.bashrc && source ~/.bashrc
```

## Theme adaptation

Parses current Omarchy `colors.toml`:
- `omarchy theme current` → `~/.config/omarchy/themes/<name>/colors.toml`
- Fallback → `~/.config/omarchy/themes/stradisymphony/colors.toml` → oldest `/usr/share/omarchy/themes/tokyo-night/colors.toml`
- Adapts `DIR_BG/FG`, `GIT_CLEAN/DIRTY_BG`, `STATUS_BG`, `CONTEXT_BG`, etc. to light/dark mode.

Truecolor fallback: if `colors.toml` missing, uses `tokyo-night` defaults (`blue #7aa2f7`, `green #9ece6a`, etc.) with 256-color fallback.

## Preview

```
~     master*   ❯
~   is blue #8171b3 / #d2d7da, git clean #98c0ff / #020202, dirty #ffcbff / #020202, ❯ green/red
```
