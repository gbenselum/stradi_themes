# Zsh — Stradisymphony Powerlevel10k Theme

Powerlevel10k config tuned to the Stradisymphony palette (background `#020202`, accent `#8171b3`, muted `#92979a`). Generated with `p10k configure`, two-line prompt.

| Segment | Color | Shows |
|---------|-------|-------|
| `dir` (line 1) | blue (`#8171b3`) | `~`-contracted path |
| `vcs` (line 1) | green clean / yellow dirty | ` branch*` + `↑/↓/⇕`, stash/untracked |
| `status` (line 2, right) | red | `✘` exit code of last command |
| `command_execution_time` | yellow | duration of last command |
| `background_jobs` | `#c396d7` | `●` jobs in background |
| `direnv` | `turquoise` | direnv allow/deny state |

Requires [Powerlevel10k](https://github.com/romkatv/powerlevel10k) and a Powerline/Nerd Font (Omarchy ships JetBrainsMono Nerd Font).

## Files

```
zsh/stradisymphony/
├── p10k.zsh               # standalone p10k config — source it AFTER the p10k theme
├── zshrc.example          # full ~/.zshrc backup from author (with inlined theme)
└── zshrc.minimal.example  # minimal snippet to wire theme + config
```

## Quick install

```bash
git clone https://github.com/gbenselum/stradi_themes.git
cd stradi_themes
./install.sh --zsh         # installs zsh theme
# or everything:
./install.sh               # omarchy + falkon + bash + zsh
```

`--zsh` does:
1. Copies `zsh/stradisymphony/p10k.zsh` → `~/.config/stradi/zsh/p10k.zsh`
2. Backs up `~/.p10k.zsh` → `~/.p10k.zsh.bak-<timestamp>` (if not already backed up)
3. Appends `source ~/.config/stradi/zsh/p10k.zsh` to `~/.zshrc` if not present

Prerequisite: Powerlevel10k itself must be installed and its theme sourced earlier in `~/.zshrc` (the config only takes effect after the theme).

Verification:
```bash
echo $POWERLEVEL9K_DIR_BACKGROUND  # → 97 129 183-ish / prompt shows two-line dir+vcs
p10k configure                     # regenerate interactively if you want to diverge
```

## Manual install

```bash
# 1. Copy config
mkdir -p ~/.config/stradi/zsh
cp zsh/stradisymphony/p10k.zsh ~/.config/stradi/zsh/p10k.zsh

# 2. Install Powerlevel10k (once), Homebrew example:
brew install powerlevel10k

# 3. In ~/.zshrc, theme FIRST, config AFTER:
cat >> ~/.zshrc <<'EOF'

# Stradisymphony Powerlevel10k Zsh Theme
source /opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f "$HOME/.config/stradi/zsh/p10k.zsh" ]] && source "$HOME/.config/stradi/zsh/p10k.zsh"
EOF

exec zsh
```

Or source the config straight from the repo without copying:
```zsh
[[ -f "$HOME/Projects/stradi_themes/zsh/stradisymphony/p10k.zsh" ]] && source "$HOME/Projects/stradi_themes/zsh/stradisymphony/p10k.zsh"
```

## Reverting

```bash
# if install.sh backed it up, restore your previous p10k config:
cp ~/.p10k.zsh.bak-* ~/.p10k.zsh && exec zsh
# or delete the appended lines from ~/.zshrc and the copied file:
rm ~/.config/stradi/zsh/p10k.zsh
```

## Tuning

Re-run `p10k configure` to tweak segments, then copy the regenerated `~/.p10k.zsh` back here if you want to keep the repo in sync.

## Preview

```
~     main*                                    ✘ 2s ●
```