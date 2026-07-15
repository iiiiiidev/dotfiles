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
    hyprland xdg-desktop-portal-hyprland hyprpolkitagent sddm
    hyprlock hypridle
    quickshell swaync fuzzel kitty dolphin hyprshot awww fish starship
    pavucontrol git
    qt6-svg qt6-declarative qt5-quickcontrols2 # sddm
    kwin layer-shell-qt layer-shell-qt5 # sddm wayland greeter (layer-shell-qt5 is aur)
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd
    noto-fonts noto-fonts-cjk noto-fonts-emoji
    catppuccin-gtk-theme-mocha
    # weather app build deps
    gcc make pkgconf gtk4 libsoup3 json-glib
)

GTK_THEME_NAME="catppuccin-mocha-mauve-standard+default"
GTK_FONT="JetBrains Mono 12"

SDDM_THEME_NAME="catppuccin-mocha-mauve"
SDDM_THEME_URL="https://github.com/catppuccin/sddm/releases/download/v1.1.2/catppuccin-mocha-mauve-sddm.zip"

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

install_configs() {
    mkdir -p "$CONFIG_DIR"
    local src name target backup
    for src in "$REPO_DIR"/.config/*; do
        name="$(basename "$src")"
        target="$CONFIG_DIR/$name"

        # already symlinked to the repo (my own setup), leave it alone
        if [ "$(readlink -f "$target" 2>/dev/null)" = "$src" ]; then
            info "$name is symlinked to the repo, skipping"
            continue
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
            backup="$target.bak.$(date +%Y%m%d%H%M%S)"
            warn "$target exists, moving to $backup"
            mv "$target" "$backup"
        fi

        cp -r "$src" "$target"
        info "copied $name -> $target"
    done

    chmod +x "$CONFIG_DIR"/hypr/scripts/*.sh
}

# ----------------------------------------------------------------- weather ---

build_weather() {
    info "building weather app"
    if ! make -C "$REPO_DIR/src/weather" install PREFIX="$HOME/.local"; then
        warn "weather build failed, skipping (rerun after installing gtk4 libsoup3 json-glib)"
        return
    fi
    info "installed weather -> $HOME/.local/bin/weather"
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

# -------------------------------------------------------------------- sddm ---

setup_sddm() {
    if [ -d "/usr/share/sddm/themes/$SDDM_THEME_NAME" ]; then
        info "sddm theme $SDDM_THEME_NAME already installed"
    else
        info "installing sddm theme $SDDM_THEME_NAME"
        local tmp
        tmp="$(mktemp -d)"
        curl -fsSL -o "$tmp/theme.zip" "$SDDM_THEME_URL"
        bsdtar -xf "$tmp/theme.zip" -C "$tmp"
        sudo mkdir -p /usr/share/sddm/themes
        sudo mv "$tmp/$SDDM_THEME_NAME" /usr/share/sddm/themes/
        rm -rf "$tmp"
    fi

    info "writing sddm config"
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/theme.conf >/dev/null <<EOF # from https://wiki.archlinux.org/title/SDDM#Wayland 2.12.1
[Theme]
Current=$SDDM_THEME_NAME
EOF
    sudo tee /etc/sddm.conf.d/10-wayland.conf >/dev/null <<'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1
EOF

    info "enabling sddm"
    sudo systemctl enable sddm.service
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
install_configs
build_weather
apply_gtk_settings
setup_sddm
fetch_wallpapers
chsh -s "$(command -v fish)"
clear
echo "Rebooting in 4 seconds"
sleep 4
reboot