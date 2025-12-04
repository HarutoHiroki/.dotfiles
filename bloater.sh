#!/usr/bin/env bash
cd "$(dirname "$0")"
REPO_ROOT="$(pwd)"
export BLOATER_ROOT="$REPO_ROOT"

set -e

# Source lib files
source ./bloat/lib/environment-variables.sh
source ./bloat/lib/functions.sh

# Default values
TARGET_USER="${SUDO_USER:-$USER}"
ZSH_PATH="$(command -v zsh || true)"
OHMYZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# Determine mode
MODE="${1:-${MODE:-}}"

if [[ -z "$MODE" ]]; then
  echo "Select your flavor of chaos:"
  echo "  1) YOLO mode              - run everything automatically, living dangerously with --noconfirm"
  echo "  2) Paranoid mode          - prompt before each command (trust issues are valid)"
  echo "  3) Dots changes only mode - only apply visual customizations (first install or after updates)"
  read -rp "Enter choice [1-3]: " choice
  case "$choice" in
    1) MODE="unattended" ;;
    2) MODE="manual" ;;
    3) MODE="customize-only" ;;
    *) echo "Invalid choice. Defaulting to paranoid mode because safety first."; MODE="manual" ;;
  esac
fi

# Determine GPU type (skip for customize-only mode)
GPU_TYPE="${2:-${GPU_TYPE:-}}"

if [[ "$MODE" != "customize-only" && -z "$GPU_TYPE" ]]; then
  echo
  echo "Choose your GPU allegiance:"
  echo "  1) AMD     - The open source champions (smooth sailing ahead)"
  echo "  2) NVIDIA  - The proprietary overlords (prepare for driver hell)"
  echo "  3) Skip    - I'll handle my own GPU drivers (brave soul)"
  read -rp "Enter choice [1-3]: " gpu_choice
  case "$gpu_choice" in
    1) GPU_TYPE="amd" ;;
    2) GPU_TYPE="nvidia" ;;
    3) GPU_TYPE="skip" ;;
    *) echo "Invalid choice. Defaulting to AMD because we value your sanity."; GPU_TYPE="amd" ;;
  esac
fi

# Prevent running as root
prevent_sudo_or_root

# Prevent running as root
prevent_sudo_or_root

echo "Bloater initializing..."
echo "Running in mode: $MODE"
if [[ "$MODE" != "customize-only" ]]; then
  echo "GPU type: $GPU_TYPE"
  echo "Target user for shell shenanigans: $TARGET_USER"
fi
echo

# ===========================================================
# 1) Install dependencies
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
  echo "Installing dependencies..."
  echo
  
  # Export variables needed by install-deps.sh
  export ask=$([[ "$MODE" == "manual" ]] && echo "true" || echo "false")
  export SKIP_SYSUPDATE=false
  export GPU_TYPE
  
  # Source the install-deps script (like end-4 does with ./setup install)
  if [[ -f "${BLOATER_ROOT}/bloat/deps/install-deps.sh" ]]; then
    source "${BLOATER_ROOT}/bloat/deps/install-deps.sh"
  else
    echo "Error: install-deps.sh not found"
    exit 1
  fi
  
  echo
  echo "✓ Dependencies installed"
  echo
fi # End of part 1

# ===========================================================
# 2) Initial Setup and Configurations
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then

# Add user to docker group (from bloater-system metapackage)
run_cmd "sudo usermod -aG docker ${TARGET_USER}"

# Install oh-my-zsh and set zsh as default shell
echo "Setting up Zsh..."
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

# Install VS Code ~~bloat~~ extensions
echo "Installing VS Code extensions..."
VSCODE_EXTENSIONS=(
aaron-bond.better-comments
alefragnani.project-manager
bradlc.vscode-tailwindcss
codezombiech.gitignore
dbaeumer.vscode-eslint
donjayamanne.git-extension-pack
donjayamanne.githistory
eamodio.gitlens
ecmel.vscode-html-css
esbenp.prettier-vscode
felipecaputo.git-project-manager
github.codespaces
github.copilot
github.copilot-chat
github.remotehub
github.vscode-pull-request-github
hookyqr.minify
icrawl.discord-vscode
janisdd.vscode-edit-csv
ms-azuretools.vscode-containers
ms-python.debugpy
ms-python.python
ms-python.vscode-pylance
ms-python.vscode-python-envs
ms-vscode-remote.remote-containers
ms-vscode-remote.remote-ssh
ms-vscode-remote.remote-ssh-edit
ms-vscode.azure-repos
ms-vscode.cmake-tools
ms-vscode.cpptools
ms-vscode.cpptools-extension-pack
ms-vscode.cpptools-themes
ms-vscode.remote-explorer
ms-vscode.remote-repositories
pkief.material-icon-theme
rakib13332.material-code
ritwickdey.liveserver
rvest.vs-code-prettier-eslint
t3dotgg.vsc-material-theme-but-i-wont-sue-you
tomoki1207.pdf
wakatime.vscode-wakatime
yzhang.markdown-all-in-one
zignd.html-css-class-completion
ziyasal.vscode-open-in-github
)

for ext in "${VSCODE_EXTENSIONS[@]}"; do
  VSCODE_EXT_CMD="code --install-extension ${ext}"
  run_cmd "$VSCODE_EXT_CMD"
done

# Configure VS Code settings (theme and icons)
echo "Configuring VS Code theme and icons..."
VSCODE_SETTINGS_DIR="${XDG_CONFIG_HOME}/Code/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

run_cmd "mkdir -p \"$VSCODE_SETTINGS_DIR\""

# Update or create settings.json with theme preferences
VSCODE_THEME_CMD="jq '. + {\"workbench.colorTheme\": \"Material Theme Ocean\", \"workbench.iconTheme\": \"material-icon-theme\"}' \"$VSCODE_SETTINGS_FILE\" 2>/dev/null > \"$VSCODE_SETTINGS_FILE.tmp\" && mv \"$VSCODE_SETTINGS_FILE.tmp\" \"$VSCODE_SETTINGS_FILE\" || echo '{\"workbench.colorTheme\": \"Material Theme Ocean\", \"workbench.iconTheme\": \"material-icon-theme\"}' > \"$VSCODE_SETTINGS_FILE\""
run_cmd "$VSCODE_THEME_CMD"

# Configure Timeshift settings
echo "Configuring Timeshift..."
TIMESHIFT_CONFIG="/etc/timeshift/timeshift.json"
TIMESHIFT_DEFAULT="/etc/timeshift/default.json"

# Initialize config if needed
run_cmd "sudo bash -c '[ ! -f \"$TIMESHIFT_CONFIG\" ] || [ ! -s \"$TIMESHIFT_CONFIG\" ] && { [ -f \"$TIMESHIFT_DEFAULT\" ] && cp \"$TIMESHIFT_DEFAULT\" \"$TIMESHIFT_CONFIG\" || echo \"{}\" > \"$TIMESHIFT_CONFIG\"; } || true'"

# Configure Timeshift settings
run_cmd "sudo jq '.btrfs_mode = \"true\" | .include_btrfs_home_for_backup = \"true\" | .schedule_daily = \"true\" | .count_daily = \"5\" | .date_format = \"%Y-%m-%d %I:%M %p\"' \"$TIMESHIFT_CONFIG\" | sudo tee \"$TIMESHIFT_CONFIG.tmp\" > /dev/null && sudo mv \"$TIMESHIFT_CONFIG.tmp\" \"$TIMESHIFT_CONFIG\""

# Configure Discord to skip host updates
echo "Configuring Discord settings..."
DISCORD_SETTINGS="${XDG_CONFIG_HOME}/discord/settings.json"
run_cmd "mkdir -p \"${XDG_CONFIG_HOME}/discord\""

# Create or update Discord settings
if [[ -f "$DISCORD_SETTINGS" && -s "$DISCORD_SETTINGS" ]]; then
  # File exists and has content, append to existing JSON
  DISCORD_UPDATE_CMD="jq '. + {\"SKIP_HOST_UPDATE\": true}' \"$DISCORD_SETTINGS\" > \"$DISCORD_SETTINGS.tmp\" && mv \"$DISCORD_SETTINGS.tmp\" \"$DISCORD_SETTINGS\""
else
  # File doesn't exist or is empty, create new JSON
  DISCORD_UPDATE_CMD="echo '{\"SKIP_HOST_UPDATE\": true}' > \"$DISCORD_SETTINGS\""
fi
run_cmd "$DISCORD_UPDATE_CMD"

# Configure PAM for Hyprlock with fingerprint support
echo "Configuring PAM for Hyprlock fingerprint authentication..."
HYPRLOCK_PAM="/etc/pam.d/hyprlock"

# Check if already configured, otherwise create the PAM file
if [[ "$MODE" == "manual" ]]; then
  PAM_CONFIG_CMD="if sudo grep -q 'pam_fprintd.so' \"$HYPRLOCK_PAM\" 2>/dev/null; then echo 'Hyprlock PAM fingerprint already configured'; else sudo tee \"$HYPRLOCK_PAM\" >/dev/null <<'PAMEOF'
auth     sufficient pam_fprintd.so
auth     include    system-auth
account  include    system-auth
password include    system-auth
session  include    system-auth
PAMEOF
fi"
else
  PAM_CONFIG_CMD="sudo grep -q 'pam_fprintd.so' \"$HYPRLOCK_PAM\" 2>/dev/null || sudo tee \"$HYPRLOCK_PAM\" >/dev/null <<'PAMEOF'
auth     sufficient pam_fprintd.so
auth     include    system-auth
account  include    system-auth
password include    system-auth
session  include    system-auth
PAMEOF"
fi
run_cmd "$PAM_CONFIG_CMD"

# Remove unused display managers
echo "Removing unused display managers (none look good)..."
REMOVE_CMD="sudo pacman -R ${PACMAN_FLAGS} sddm gdm lightdm"
run_cmd "$REMOVE_CMD"

echo "Installing bootup themes..."

# Install CyberGRUB-2077 theme
echo "Installing CyberGRUB-2077 theme..."
CYBERGRUB_CMD="git clone https://github.com/adnksharp/CyberGRUB-2077.git && sudo ./CyberGRUB-2077/install.sh && rm -rf CyberGRUB-2077"
run_cmd "$CYBERGRUB_CMD"

# Add plymouth to mkinitcpio.conf HOOKS
echo "Adding plymouth to mkinitcpio.conf..."
MKINIT_PLYMOUTH_CMD="sudo sed -i 's/^HOOKS=\(.*\)\(base udev\)/HOOKS=\\1\\2 plymouth/' /etc/mkinitcpio.conf || sudo sed -i 's/^HOOKS=\(.*\)\(systemd\)/HOOKS=\\1\\2 plymouth/' /etc/mkinitcpio.conf"
run_cmd "$MKINIT_PLYMOUTH_CMD"

# Install chika Plymouth theme
echo "Installing chika Plymouth theme..."
CHIKA_CMD="git clone https://git.jamjar.ws/strat/chika_plymouth.git && sudo cp -r chika_plymouth/theme /usr/share/plymouth/themes/chika && rm -rf chika_plymouth"
UPDATE_PLYMOUTH_CMD="sudo plymouth-set-default-theme -R chika"
run_cmd "$CHIKA_CMD"
run_cmd "$UPDATE_PLYMOUTH_CMD"
fi # End of part 3

# ===========================================================
# 4) Apply customizations
# ===========================================================
echo "Applying the secret sauce..."

# Copy .zshrc
echo "Copying custom .zshrc..."
if [[ -f "$HOME/.zshrc" ]]; then
  echo "Backing up existing .zshrc to .zshrc.backup.$(date +%Y%m%d_%H%M%S)"
  run_cmd "cp \"$HOME/.zshrc\" \"$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)\""
fi
run_cmd "cp -f \"${BLOATER_ROOT}/bloat/dots/.zshrc\" \"$HOME/\""

# Copy wallpaper directory
echo "Copying wallpaper directory..."
run_cmd "mkdir -p \"$HOME/Wallpapers\""
run_cmd "cp -r \"${BLOATER_ROOT}/bloat/wallpaper\"/* \"$HOME/Wallpapers/\""

# Copy illogical-impulse config
echo "Copying custom illogical-impulse config..."
II_CONFIG_DIR="${XDG_CONFIG_HOME}/illogical-impulse"
run_cmd "cp -f \"${BLOATER_ROOT}/bloat/dots/.config/illogical-impulse/config.json\" \"$II_CONFIG_DIR/\""

# Update wallpaper path to current user
echo "Updating wallpaper path for current user..."
run_cmd "sed -i 's|/home/[^/]*/Wallpapers/|/home/'\"$TARGET_USER\"'/Wallpapers/|g' \"$II_CONFIG_DIR/config.json\""

# Monitor config
echo "Configuring monitor settings..."
HYPR_CONF_FILE="${XDG_CONFIG_HOME}/hypr/monitors.conf"
MONITOR_LINE='monitor = , preferred, auto, 1.333334'
run_cmd "echo \"$MONITOR_LINE\" >> \"$HYPR_CONF_FILE\""

# Modify Kitty to use zsh
echo "Updating Kitty terminal to use Zsh..."
KITTY_FILE="${XDG_CONFIG_HOME}/kitty/kitty.conf"
run_cmd "sed -i \"s/^shell fish/# shell fish\\n\\n# Use zsh\\nshell zsh/\" \"$KITTY_FILE\""

# Modify Hyprland keybinds to add Vivaldi
echo "Prioritizing Vivaldi in keybinds..."
HYPR_KEYBINDS_FILE="${XDG_CONFIG_HOME}/hypr/hyprland/keybinds.conf"
run_cmd "sed -i \"s|bind = Super, W, exec, ~/.config/hypr/hyprland/scripts/launch_first_available.sh \\\"google-chrome-stable\\\" \\\"zen-browser\\\" \\\"firefox\\\" \\\"brave\\\" \\\"chromium\\\" \\\"microsoft-edge-stable\\\" \\\"opera\\\" \\\"librewolf\\\" # Browser|bind = Super, W, exec, ~/.config/hypr/hyprland/scripts/launch_first_available.sh \\\"vivaldi\\\" \\\"google-chrome-stable\\\" \\\"zen-browser\\\" \\\"firefox\\\" \\\"brave\\\" \\\"chromium\\\" \\\"microsoft-edge-stable\\\" \\\"opera\\\" \\\"librewolf\\\" # Browser|\" \"$HYPR_KEYBINDS_FILE\""

# Copy Hyprlock helper script
echo "Copying Hyprlock helper script..."
HYPRLOCK_DIR="${XDG_CONFIG_HOME}/hypr/hyprlock"
run_cmd "mkdir -p \"$HYPRLOCK_DIR\""
run_cmd "cp -f \"${BLOATER_ROOT}/bloat/dots/.config/hypr/hyprlock/get_wallpaper_path.sh\" \"$HYPRLOCK_DIR/\""

# Copy custom Hyprlock config
echo "Copying custom Hyprlock config..."
HYPRLOCK_CONF="${XDG_CONFIG_HOME}/hypr/hyprlock.conf"
if [[ -f "$HYPRLOCK_CONF" ]]; then
  echo "Backing up existing hyprlock.conf to hyprlock.conf.backup.$(date +%Y%m%d_%H%M%S)"
  run_cmd "cp \"$HYPRLOCK_CONF\" \"$HYPRLOCK_CONF.backup.$(date +%Y%m%d_%H%M%S)\""
fi
run_cmd "cp -f \"${BLOATER_ROOT}/bloat/dots/.config/hypr/hyprlock.conf\" \"$HYPRLOCK_CONF\""

# ===========================================================
# Add your own customizations here!
# Use run_cmd for any modifications you want to persist
# ===========================================================

echo "✓ Customizations applied!"
# End of part 4

echo
echo "Bloating complete! Your system is now beautifully bloated."
echo "Mode: $MODE"
if [[ "$MODE" != "customize-only" ]]; then
  if [[ "$GPU_TYPE" == "nvidia" ]]; then
    echo "Remember: You chose NVIDIA. May the driver gods be ever in your favor."
  elif [[ "$GPU_TYPE" == "skip" ]]; then
    echo "GPU drivers skipped. Don't forget to install them yourself!"
  fi
fi
echo
echo "Time to reboot and enjoy your feature-packed monstrosity!"
