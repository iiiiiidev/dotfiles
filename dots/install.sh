#!/usr/bin/env bash
#
#

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPERS_REPO="https://github.com/iiiiiidev/wallpapers"
WALLPAPERS_DIR="$HOME/wallpapers"

SKIP_PACKAGES=0
[ "${1:-}" = "--skip-packages" ] && SKIP_PACKAGES=1

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

ARCH_PACKAGES=(
    hyprland xdg-desktop-portal-hyprland hyprpolkitagent
    quickshell swaync fuzzel kitty dolphin hyprshot awww
    pavucontrol git
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd
    noto-fonts noto-fonts-cjk noto-fonts-emoji
    catppuccin-gtk-theme-mocha
)

GTK_THEME_NAME="catppuccin-mocha-mauve-standard+default"
GTK_FONT="JetBrains Mono 12"

install_arch() {
    local missing=() aur=() pkg
    for pkg in "${ARCH_PACKAGES[@]}"; do
        pacman -Qq "$pkg" >/dev/null 2>&1 && continue
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        else
            aur+=("$pkg")
        fi
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        info "installing: ${missing[*]}"
        sudo pacman -S --needed "${missing[@]}"
    fi

    if [ "${#aur[@]}" -gt 0 ]; then
        local helper
        helper=$(command -v paru || command -v yay || true)
        if [ -n "$helper" ]; then
            info "installing from aur: ${aur[*]}"
            "$helper" -S --needed "${aur[@]}"
        else
            info "no aur helper found, building with makepkg: ${aur[*]}"
            sudo pacman -S --needed base-devel git
            local builddir
            builddir="$(mktemp -d)"
            for pkg in "${aur[@]}"; do
                git clone --depth=1 "https://aur.archlinux.org/$pkg.git" "$builddir/$pkg"
                (cd "$builddir/$pkg" && makepkg -si --noconfirm) || warn "failed to build $pkg"
            done
            rm -rf "$builddir"
        fi
    fi
}
install_packages() {
    if ! command -v pacman >/dev/null; then
        warn "this script only supports arch"
        warn "install these packages yourself, then rerun with --skip-packages:"
        warn "  ${ARCH_PACKAGES[*]}"
        exit 1
    fi
    install_arch
}

# ----------------------------------------------------------------- configs ---

link_configs() {
    mkdir -p "$CONFIG_DIR"
    local src name target backup
    for src in "$REPO_DIR"/.config/*/; do
        src="${src%/}"
        name="$(basename "$src")"
        target="$CONFIG_DIR/$name"

        if [ "$(readlink -f "$target" 2>/dev/null)" = "$src" ]; then
            info "$name already linked"
            continue
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
            backup="$target.bak.$(date +%Y%m%d%H%M%S)"
            warn "$target exists, moving to $backup"
            mv "$target" "$backup"
        fi

        ln -s "$src" "$target"
        info "linked $name -> $target"
    done

    chmod +x "$REPO_DIR"/.config/hypr/scripts/*.sh
}

# --------------------------------------------------------------- gtk theme ---

apply_gtk_settings() {
    if ! command -v gsettings >/dev/null; then
        warn "gsettings not found, skipping gtk theme/font settings"
        return
    fi
    info "applying gtk theme '$GTK_THEME_NAME' and font '$GTK_FONT'"
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME" || warn "failed to set gtk-theme"
    gsettings set org.gnome.desktop.interface font-name "$GTK_FONT" || warn "failed to set font"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || warn "failed to set color-scheme"
}

# -------------------------------------------------------------- wallpapers ---

fetch_wallpapers() {
    if [ -d "$WALLPAPERS_DIR/.git" ]; then
        info "updating wallpapers"
        git -C "$WALLPAPERS_DIR" pull --ff-only || warn "wallpaper update failed, keeping current copy"
    elif [ -e "$WALLPAPERS_DIR" ]; then
        warn "$WALLPAPERS_DIR exists but is not a git clone, leaving it alone"
    else
        info "cloning wallpapers to $WALLPAPERS_DIR"
        git clone --depth=1 "$WALLPAPERS_REPO" "$WALLPAPERS_DIR"
    fi
}

# -------------------------------------------------------------------- main ---

[ "$SKIP_PACKAGES" -eq 1 ] || install_packages
command -v git >/dev/null || die "git is required"
link_configs
apply_gtk_settings
fetch_wallpapers

info "done"
