#!/usr/bin/env bash

PACMAN_PACKAGES=$(cat <<'PKGS'
# Fonts
adobe-source-han-sans-jp-fonts
adobe-source-han-serif-jp-fonts
noto-fonts-cjk
otf-ipaexfont
ttf-jigmo
ttf-vlgothic
cantarell-fonts
ttf-dejavu

# Development
git
zip
seahorse

# X11
xorg-xhost

# Power management
upower
acpid
powertop
power-profiles-daemon

# Browser
vivaldi

# Biometrics
libfprint
fprintd

# Boot visuals
plymouth

# Shell
zsh

# Audio
easyeffects

# Containers
docker

# System monitoring
btop
fastfetch

# Flatpak
flatpak
flatpak-kcm

# Media / tools
mpv
imv
fwupd

# VPN
openvpn
networkmanager-openvpn
wireguard-tools

# Network tools
nmap
wireshark-cli
wireshark-qt

# Gaming
wine
lutris
PKGS
)

echo "=== Raw package list output ==="
echo "$PACMAN_PACKAGES" | sed '/^\s*#/d;/^\s*$/d' | tr '\n' ' '
echo ""
echo ""
echo "=== What would be passed to pacman ==="
echo "sudo pacman -Syu --needed $(echo "$PACMAN_PACKAGES" | sed '/^\s*#/d;/^\s*$/d' | tr '\n' ' ')"
echo ""
read -rp "Press Enter to exit..."
