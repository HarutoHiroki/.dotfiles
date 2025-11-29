#!/usr/bin/env bash
set -u

# Determine mode
MODE="${1:-${MODE:-}}"

if [[ -z "$MODE" ]]; then
  echo "Select setup mode:"
  echo "  1) unattended       - run everything automatically with --noconfirm"
  echo "  2) manual           - prompt before each command"
  echo "  3) customize-only   - only apply customizations (part 6)"
  read -rp "Enter choice [1-3]: " choice
  case "$choice" in
    1) MODE="unattended" ;;
    2) MODE="manual" ;;
    3) MODE="customize-only" ;;
    *) echo "Invalid choice. Defaulting to manual."; MODE="manual" ;;
  esac
fi

# Determine GPU type (skip for customize-only mode)
GPU_TYPE="${2:-${GPU_TYPE:-}}"

if [[ "$MODE" != "customize-only" && -z "$GPU_TYPE" ]]; then
  echo
  echo "Select GPU type:"
  echo "  1) AMD     - install AMD graphics stack (Mesa, Vulkan, VDPAU)"
  echo "  2) NVIDIA  - install NVIDIA proprietary drivers and utilities"
  read -rp "Enter choice [1-2]: " gpu_choice
  case "$gpu_choice" in
    1) GPU_TYPE="amd" ;;
    2) GPU_TYPE="nvidia" ;;
    *) echo "Invalid choice. Defaulting to AMD."; GPU_TYPE="amd" ;;
  esac
fi

TARGET_USER="${SUDO_USER:-$USER}"
ZSH_PATH="$(command -v zsh || true)"
OHMYZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# --------------------- Helper Functions ---------------------

run_cmd() {
  local cmd="$1"
  if [[ "$MODE" == "manual" ]]; then
    echo
    echo "About to run:"
    echo "  $cmd"
    read -rp "Run this command now? [Y/n] " yn
    yn=${yn:-Y}
    if [[ "${yn^^}" == "Y" || "${yn}" == "y" || "${yn}" == "" ]]; then
      eval "$cmd"
    else
      echo "Skipped."
    fi
  else # unattended
    echo "[RUNNING] $cmd"
    eval "$cmd"
  fi
}

# --------------------- Setup Variables ----------------------

if [[ "$MODE" == "unattended" ]]; then
  PACMAN_FLAGS="--noconfirm --needed"
  YAY_FLAGS="--noconfirm"
else
  PACMAN_FLAGS="--needed"
  YAY_FLAGS=""
fi

echo "Running in mode: $MODE"
if [[ "$MODE" != "customize-only" ]]; then
  echo "GPU type: $GPU_TYPE"
  echo "Target user for chsh: $TARGET_USER"
fi
echo

# ===========================================================
# 1) Enable multilib
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
enable_multilib() {
  local pacman_conf="/etc/pacman.conf"
  if sudo grep -qE '^[[:space:]]*\[multilib\]' "$pacman_conf"; then
    echo "multilib already enabled"
    return 0
  fi

  echo "Enabling multilib"
  if sudo sed -n '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ p' "$pacman_conf" | grep -q '\[multilib\]'; then
    sudo sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' "$pacman_conf"
  else
    sudo bash -c "cat >>$pacman_conf <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF"
  fi

  echo "Refreshing pacman DB..."
  run_cmd "sudo pacman -Syy"
}

run_cmd "enable_multilib"
fi # End of part 1

# ===========================================================
# 2) Install pacman packages
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
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

PACMAN_CMD="sudo pacman -Syu ${PACMAN_FLAGS} $(echo \"$PACMAN_PACKAGES\" | sed '/^\s*#/d;/^\s*$/d' | tr '\n' ' ')"
run_cmd "$PACMAN_CMD"

# Add user to docker group
run_cmd "sudo usermod -aG docker ${TARGET_USER}"
fi # End of part 2

# ===========================================================
# 2b) Install GPU-specific packages
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
if [[ "$GPU_TYPE" == "amd" ]]; then
  GPU_PACKAGES=$(cat <<'GPUPKGS'
mesa
lib32-mesa
mesa-vdpau
lib32-mesa-vdpau
vulkan-radeon
lib32-vulkan-radeon
glu
lib32-glu
vulkan-icd-loader
lib32-vulkan-icd-loader
GPUPKGS
)
  GPU_CMD="sudo pacman -S ${PACMAN_FLAGS} $(echo \"$GPU_PACKAGES\" | sed '/^\s*#/d;/^\s*$/d' | tr '\n' ' ')"
  echo "Installing AMD graphics stack..."
  run_cmd "$GPU_CMD"
elif [[ "$GPU_TYPE" == "nvidia" ]]; then
  GPU_PACKAGES=$(cat <<'GPUPKGS'
nvidia
nvidia-utils
lib32-nvidia-utils
nvidia-settings
vulkan-icd-loader
lib32-vulkan-icd-loader
glu
lib32-glu
GPUPKGS
)
  GPU_CMD="sudo pacman -S ${PACMAN_FLAGS} $(echo \"$GPU_PACKAGES\" | sed '/^\s*#/d;/^\s*$/d' | tr '\n' ' ')"
  echo "Installing NVIDIA graphics stack..."
  run_cmd "$GPU_CMD"
fi
fi # End of part 2b

# ===========================================================
# 3) Install oh-my-zsh and set zsh as default shell
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
OHMYZSH_CMD="env RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL ${OHMYZSH_INSTALL_URL})\""
run_cmd "$OHMYZSH_CMD"

if [[ -z "$ZSH_PATH" ]]; then
  ZSH_PATH="$(command -v zsh || true)"
fi

if [[ -n "$ZSH_PATH" ]]; then
  CHSH_CMD="sudo chsh -s ${ZSH_PATH} ${TARGET_USER}"
  run_cmd "$CHSH_CMD"
else
  echo "zsh not found; skipping chsh."
fi
fi # End of part 3

# ===========================================================
# 4) yay AUR installs
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
AUR_PACKAGES="wireguard-gui-bin feishin steam protonup-qt minecraft-launcher visual-studio-code-bin bottles"
YAY_CMD="yay -S ${YAY_FLAGS} ${AUR_PACKAGES}"
run_cmd "$YAY_CMD"
fi # End of part 4

# ===========================================================
# 5) Bootup themes install
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
# Install CyberGRUB-2077 theme
CYBERGRUB_CMD="git clone https://github.com/adnksharp/CyberGRUB-2077.git && sudo ./CyberGRUB-2077/install.sh && rm -rf CyberGRUB-2077"
run_cmd "$CYBERGRUB_CMD"

# Install chika Plymouth theme
CHIKA_CMD="git clone https://git.jamjar.ws/strat/chika_plymouth.git && sudo cp -r chika_plymouth/theme /usr/share/plymouth/themes/chika && rm -rf chika_plymouth"
UPDATE_PLYMOUTH_CMD="sudo plymouth-set-default-theme -R chika"
run_cmd "$CHIKA_CMD"
run_cmd "$UPDATE_PLYMOUTH_CMD"
fi # End of part 5

# ===========================================================
# 6) Apply customizations
# ===========================================================
echo "Applying customizations..."
echo

# Copy .zshrc
run_cmd "cp -f .zshrc \"$HOME/\""

# Monitor config
HYPR_CONF_FILE="$HOME/.config/hypr/monitors.conf"
MONITOR_LINE='monitor = , preferred, auto, 1.333334'
run_cmd "echo \"$MONITOR_LINE\" >> \"$HYPR_CONF_FILE\""

# Modify Kitty to use zsh
KITTY_FILE="$HOME/.config/kitty/kitty.conf"
run_cmd "sed -i \"s/^shell fish/# shell fish\\n\\n# Use zsh\\nshell zsh/\" \"$KITTY_FILE\""

# Modify Hyprland keybinds to add Vivaldi
HYPR_KEYBINDS_FILE="$HOME/.config/hypr/hyprland/keybinds.conf"
run_cmd "sed -i \"s|bind = Super, W, exec, ~/.config/hypr/hyprland/scripts/launch_first_available.sh \\\"google-chrome-stable\\\" \\\"zen-browser\\\" \\\"firefox\\\" \\\"brave\\\" \\\"chromium\\\" \\\"microsoft-edge-stable\\\" \\\"opera\\\" \\\"librewolf\\\" # Browser|bind = Super, W, exec, ~/.config/hypr/hyprland/scripts/launch_first_available.sh \\\"vivaldi\\\" \\\"google-chrome-stable\\\" \\\"zen-browser\\\" \\\"firefox\\\" \\\"brave\\\" \\\"chromium\\\" \\\"microsoft-edge-stable\\\" \\\"opera\\\" \\\"librewolf\\\" # Browser|\" \"$HYPR_KEYBINDS_FILE\""

# ===========================================================
# 7) Remove display managers
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
REMOVE_CMD="sudo pacman -R ${PACMAN_FLAGS} sddm gdm lightdm"
run_cmd "$REMOVE_CMD"
fi # End of part 7

echo
echo "Script finished (mode: $MODE)."
