#!/usr/bin/env bash
#
# Stradi Themes - unattended installer
#
# Installs:
#   1. Omarchy theme  "stradisymphony"  -> ~/.config/omarchy/themes/stradisymphony
#   2. Falkon theme   "stradisymphony"  -> ~/.local/share/falkon/themes/stradisymphony
#   3. Sets Falkon's active theme      -> ~/.config/falkon/profiles/<active>/settings.ini
#
# Designed to run with zero interaction. If Falkon is running it is closed
# first so the settings edit is not overwritten on exit.
#
# Usage:
#   ./install.sh                 # install everything
#   ./install.sh --omarchy       # only the omarchy theme
#   ./install.sh --falkon        # only the falkon theme
#   ./install.sh --launch        # also relaunch falkon at the end
#   ./install.sh --skip-apply    # copy files but do NOT run `omarchy theme set`
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="stradisymphony"
DO_OMARCHY=1
DO_FALKON=1
DO_LAUNCH=0
DO_APPLY_OMARCHY=1

for arg in "$@"; do
    case "$arg" in
        --omarchy) DO_FALKON=0 ;;
        --falkon) DO_OMARCHY=0 ;;
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

log "done."