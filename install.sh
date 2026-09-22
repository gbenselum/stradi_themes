#!/usr/bin/env bash
#
# Stradi Themes - unattended installer
#
# Installs:
#   1. Omarchy theme  "stradisymphony"  -> ~/.config/omarchy/themes/stradisymphony
#   2. Falkon theme   "stradisymphony"  -> ~/.local/share/falkon/themes/stradisymphony
#   3. Sets Falkon's active theme      -> ~/.config/falkon/profiles/<active>/settings.ini
#   4. Bash agnoster  "stradisymphony"  -> ~/.config/stradi/bash/agnoster.sh + append to ~/.bashrc
#   5. Zsh p10k        "stradisymphony"  -> ~/.config/stradi/zsh/p10k.zsh + append to ~/.zshrc
#
# Designed to run with zero interaction. If Falkon is running it is closed
# first so the settings edit is not overwritten on exit.
#
# Usage:
#   ./install.sh                 # install everything
#   ./install.sh --omarchy       # only the omarchy theme
#   ./install.sh --falkon        # only the falkon theme
#   ./install.sh --bash          # only the bash agnoster theme
#   ./install.sh --zsh           # only the zsh powerlevel10k config
#   ./install.sh --launch        # also relaunch falkon at the end
#   ./install.sh --skip-apply    # copy files but do NOT run `omarchy theme set`
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="stradisymphony"
DO_OMARCHY=1
DO_FALKON=1
DO_BASH=1
DO_ZSHP10K=1
DO_LAUNCH=0
DO_APPLY_OMARCHY=1

for arg in "$@"; do
    case "$arg" in
        --omarchy) DO_FALKON=0; DO_BASH=0; DO_ZSHP10K=0 ;;
        --falkon) DO_OMARCHY=0; DO_BASH=0; DO_ZSHP10K=0 ;;
        --bash) DO_OMARCHY=0; DO_FALKON=0; DO_ZSHP10K=0 ;;
        --zsh) DO_OMARCHY=0; DO_FALKON=0; DO_BASH=0 ;;
        --launch) DO_LAUNCH=1 ;;
        --skip-apply) DO_APPLY_OMARCHY=0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

log() { printf '[stradi] %s\n' "$1"; }
die() { printf '[stradi] ERROR: %s\n' "$1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. Omarchy theme
# ---------------------------------------------------------------------------
if [ "$DO_OMARCHY" -eq 1 ]; then
    SRC="$REPO_DIR/omarchy/$THEME_NAME"
    DST="$HOME/.config/omarchy/themes/$THEME_NAME"

    [ -d "$SRC" ] || die "omarchy theme source not found: $SRC"

    mkdir -p "$DST"
    # Copy everything except hidden dotfiles (e.g. .aether-managed markers).
    shopt -s dotglob
    for entry in "$SRC"/*; do
        base="$(basename "$entry")"
        case "$base" in
            .) continue ;;
            ..) continue ;;
            .*)
                log "skipping hidden file: $base"
                continue
                ;;
        esac
        cp -a "$entry" "$DST/"
    done
    shopt -u dotglob
    log "omarchy theme copied to $DST"

    if [ "$DO_APPLY_OMARCHY" -eq 1 ] && command -v omarchy >/dev/null 2>&1; then
        log "applying omarchy theme: $THEME_NAME"
        omarchy theme set "$THEME_NAME"
    elif [ "$DO_APPLY_OMARCHY" -eq 0 ]; then
        log "skipping 'omarchy theme set' (--skip-apply)"
    else
        log "omarchy CLI not found; apply later with: omarchy theme set $THEME_NAME"
    fi
fi

# ---------------------------------------------------------------------------
# 2. Falkon theme
# ---------------------------------------------------------------------------
if [ "$DO_FALKON" -eq 1 ]; then
    SRC="$REPO_DIR/falkon/$THEME_NAME"
    DST="$HOME/.local/share/falkon/themes/$THEME_NAME"

    [ -d "$SRC" ] || die "falkon theme source not found: $SRC"

    # Make sure Falkon is closed so it cannot overwrite settings on exit.
    if pgrep -x falkon >/dev/null 2>&1; then
        log "closing running Falkon instance"
        pkill -x falkon || true
        for _ in $(seq 1 20); do
            pgrep -x falkon >/dev/null 2>&1 || break
            sleep 0.5
        done
    fi

    mkdir -p "$DST"
    cp -a "$SRC/." "$DST/"
    log "falkon theme copied to $DST"

    # -----------------------------------------------------------------------
    # 2b. Determine the active Falkon profile
    # -----------------------------------------------------------------------
    PROFILES_INI="$HOME/.config/falkon/profiles/profiles.ini"
    PROFILE="default"
    if [ -f "$PROFILES_INI" ]; then
        # [General] startupProfile=... ; fall back to scanning [profiles] section
        startup="$(sed -n 's/^startupProfile=\(.*\)/\1/p' "$PROFILES_INI" | tail -1 | tr -d '[:space:]')"
        if [ -n "$startup" ]; then
            PROFILE="$startup"
        else
            path="$(sed -n 's/^path\[0\]=\(.*\)/\1/p' "$PROFILES_INI" | tail -1 | tr -d '[:space:]')"
            [ -n "$path" ] && PROFILE="$path"
        fi
    fi

    SETTINGS="$HOME/.config/falkon/profiles/$PROFILE/settings.ini"
    [ -f "$SETTINGS" ] || die "falkon settings not found: $SETTINGS"

    # -----------------------------------------------------------------------
    # 2c. Set activeTheme=stradisymphony under [Themes]
    #     QSettings uses case-sensitive keys; use awk (not python configparser).
    # -----------------------------------------------------------------------
    awk -v theme="$THEME_NAME" '
        /^\[Themes\]/ { in_themes=1; print; next }
        /^\[/        { in_themes=0 }
        {
            if (in_themes && $0 ~ /^activeTheme=/) { print "activeTheme=" theme; replaced=1 }
            else print
        }
        END {
            if (!replaced) {
                print ""
                print "[Themes]"
                print "activeTheme=" theme
            }
        }
    ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    log "falkon activeTheme set to '$THEME_NAME' in $SETTINGS"

    if [ "$DO_LAUNCH" -eq 1 ]; then
        log "launching falkon"
        nohup falkon >/dev/null 2>&1 &
    else
        log "falkon installed. You can launch it anytime (theme is saved in settings)."
    fi
fi

# ---------------------------------------------------------------------------
# 3. Bash agnoster theme
# ---------------------------------------------------------------------------
if [ "$DO_BASH" -eq 1 ]; then
    SRC="$REPO_DIR/bash/$THEME_NAME/agnoster.sh"
    DST_DIR="$HOME/.config/stradi/bash"
    DST="$DST_DIR/agnoster.sh"

    if [ ! -f "$SRC" ]; then
        log "bash agnoster source not found: $SRC (skipping bash install)"
    else
        mkdir -p "$DST_DIR"
        cp -a "$SRC" "$DST"
        log "bash agnoster copied to $DST"

        # Backup ~/.bashrc if no recent backup exists
        BASHRC="$HOME/.bashrc"
        if [ -f "$BASHRC" ]; then
            # Only backup if not already backed up today (avoid spamming)
            if ! ls "$HOME"/.bashrc.bak-* 1>/dev/null 2>&1; then
                cp -a "$BASHRC" "$HOME/.bashrc.bak-$(date +%Y%m%d-%H%M%S)"
                log "backed up $BASHRC"
            fi
            SOURCE_LINE='[[ -f "$HOME/.config/stradi/bash/agnoster.sh" ]] && source "$HOME/.config/stradi/bash/agnoster.sh"'
            if ! grep -qF 'stradi/bash/agnoster.sh' "$BASHRC" 2>/dev/null; then
                printf '\n# Stradisymphony Bash Agnoster Theme\n%s\n' "$SOURCE_LINE" >> "$BASHRC"
                log "appended agnoster source to $BASHRC"
            else
                log "agnoster source already in $BASHRC"
            fi
            log "bash agnoster installed. Run: source ~/.bashrc  (or open new terminal)"
            log "toggles: agnoster_disable / agnoster_enable / agnoster_reload_theme"
        else
            log "no ~/.bashrc found; theme is at $DST, source it manually"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 4. Zsh Powerlevel10k theme
# ---------------------------------------------------------------------------
if [ "$DO_ZSHP10K" -eq 1 ]; then
    SRC="$REPO_DIR/zsh/$THEME_NAME/p10k.zsh"
    DST_DIR="$HOME/.config/stradi/zsh"
    DST="$DST_DIR/p10k.zsh"
    ZSHRC="$HOME/.zshrc"

    if [ ! -f "$SRC" ]; then
        log "zsh p10k source not found: $SRC (skipping zsh install)"
    else
        mkdir -p "$DST_DIR"
        cp -a "$SRC" "$DST"
        log "zsh p10k config copied to $DST"

        if [ -f "$ZSHRC" ]; then
            # Only backup if not already backed up (avoid spamming)
            if ! ls "$HOME"/.p10k.zsh.bak-* 1>/dev/null 2>&1 && [ -f "$HOME/.p10k.zsh" ]; then
                cp -a "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.bak-$(date +%Y%m%d-%H%M%S)"
                log "backed up $HOME/.p10k.zsh"
            fi
            SOURCE_LINE='[[ -f "$HOME/.config/stradi/zsh/p10k.zsh" ]] && source "$HOME/.config/stradi/zsh/p10k.zsh"'
            if ! grep -qF 'stradi/zsh/p10k.zsh' "$ZSHRC" 2>/dev/null; then
                printf '\n# Stradisymphony Zsh Powerlevel10k Theme\n%s\n' "$SOURCE_LINE" >> "$ZSHRC"
                log "appended p10k config source to $ZSHRC"
            else
                log "p10k config source already in $ZSHRC"
            fi
            log "zsh p10k installed. Run: exec zsh  (or open new terminal)"
            log "note: Powerlevel10k itself must be installed and its theme sourced BEFORE this config in ~/.zshrc"
        else
            log "no ~/.zshrc found; config is at $DST, source it after the p10k theme manually"
        fi
    fi
fi

log "done."