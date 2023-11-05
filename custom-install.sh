#!/bin/bash

# Official Example: https://github.com/endeavouros-team/Important-news/blob/main/user_commands.bash.example

GITHUB_RELEASES_DOWNLOAD_URL="https://github.com/HKM-UNI/linux65-aso-4t3/releases/download/v6.5.5-arch1.hkm"
PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"
GRUB_THEMES_DIR="/usr/share/grub/themes"

KERNEL_PKGS=(
    "linux-6.5.5.arch1-1-x86_64.pkg.tar.zst"
    "linux-docs-6.5.5.arch1-1-x86_64.pkg.tar.zst"
    "linux-headers-6.5.5.arch1-1-x86_64.pkg.tar.zst"
)

function msg() {
    local severity="$1"
    local msg="$2"
    echo "==> user_commands.bash: $severity: $msg"
}

if [ "$EUID" -ne 0 ]
  then msg ERROR "You must run this script as super user"
  exit
fi

function setup_grub() {
    msg INFO "Restoring GRUB custom config..."
    cp ./grub /etc/default/grub

    msg INFO "Setting CyberRe GRUB theme..."
    unzip ./CyberRe.zip
    cp -r ./CyberRe $GRUB_THEMES_DIR
}

function setup_playmouth() {
    command -v plymouth > /dev/null || {
        msg INFO "Installing plymouth..."
        pacman -S plymouth --noconfirm
    }

    msg INFO "Restoring Plymouth custom config (Incl. theme)..."
    cp ./plymouthd.conf /etc/plymouth/plymouthd.conf

    msg INFO "Setting hkm-uni Plymouth theme..."
    unzip ./hkm-uni.zip
    cp -r ./hkm-uni $PLYMOUTH_THEMES_DIR
}

function setup_touchegg() {
    command -v touche > /dev/null || {
        msg INFO "Installing touchegg (Service) + touche (GUI)..."
        pacman -U ./touche-2.0.11-1-x86_64.pkg.tar.zst --noconfirm
    }

    local username="$1"
    local home="/home/$username"

    if [[ -z "$username" || ! -d "$home" ]] ; then
        msg WARNING "The user is not properly configured. It will not be possible to restore custom touchegg gestures."
        sleep 2
        return
    fi

    [[ ! -d "$home/.config/touchegg" ]] && {
        msg INFO "Creating touchegg's .config dir..."
        mkdir -p "$home/.config/touchegg"
    }

    msg INFO "Restoring touchegg gestures..."
    cp ./touchegg.conf "$home/.config/touchegg/touchegg.conf"

    msg INFO "Fixing config's ownership for '$username'..."
    chown -R $username:$username "$home/.config/"

    msg INFO "Enabling touchegg service..."
    systemctl enable touchegg
}

function setup_kernel() {
    msg INFO "Downloading the custom kernel..."
    for pkg in "${KERNEL_PKGS[@]}"; do
        wget -nc "$GITHUB_RELEASES_DOWNLOAD_URL/$pkg"
    done

    msg INFO "Installing the custom kernel..."
    pacman -U "${KERNEL_PKGS[@]}" --noconfirm

    msg INFO "Ignoring kernel upgrades..."
    sed -r -i 's/#?(IgnorePkg\s*=.*)/\1 linux/' /etc/pacman.conf
}

function update_grub() {
    msg INFO "Updating GRUB..."
    grub-mkconfig -o /boot/grub/grub.cfg
}

function main() {
    setup_grub
    setup_playmouth
    setup_touchegg
    setup_kernel
    # Instalar el nuevo kernel deberia activar la recompilacion de initrds con dracut
    # Por lo que solo queda actualizar el GRUB
    update_grub

    # Esto es una opcion experimental para comprobar los logs durante un momento
    msg INFO "Finishing up..."
    sleep 5
}

main
