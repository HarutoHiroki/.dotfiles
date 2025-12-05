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
  echo -e "${STY_CYAN}Select your flavor of chaos:${STY_RST}"
  echo -e "  ${STY_GREEN}1)${STY_RST} YOLO mode              - run everything automatically, living dangerously with --noconfirm"
  echo -e "  ${STY_YELLOW}2)${STY_RST} Paranoid mode          - prompt before each command (trust issues are valid)"
  echo -e "  ${STY_BLUE}3)${STY_RST} Dots changes only mode - only apply visual customizations (first install or after updates)"
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
  echo -e "${STY_CYAN}Choose your GPU allegiance:${STY_RST}"
  echo -e "  ${STY_GREEN}1)${STY_RST} AMD     - The open source champions (smooth sailing ahead)"
  echo -e "  ${STY_RED}2)${STY_RST} NVIDIA  - The proprietary overlords (prepare for driver hell)"
  echo -e "  ${STY_YELLOW}3)${STY_RST} Skip    - I'll handle my own GPU drivers (brave soul)"
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

echo -e "${STY_BOLD}${STY_CYAN}Bloater initializing...${STY_RST}"
echo -e "${STY_BLUE}Running in mode:${STY_RST} ${STY_YELLOW}$MODE${STY_RST}"
if [[ "$MODE" != "customize-only" ]]; then
  echo -e "${STY_BLUE}GPU type:${STY_RST} ${STY_GREEN}$GPU_TYPE${STY_RST}"
  echo -e "${STY_BLUE}Target user for shell shenanigans:${STY_RST} ${STY_CYAN}$TARGET_USER${STY_RST}"
fi
echo

# Initialize sudo keepalive for the entire process
if [[ "$MODE" != "customize-only" ]]; then
  sudo_init_keepalive
  # Set trap to cleanup when script exits
  trap sudo_stop_keepalive EXIT INT TERM
fi

# ===========================================================
# 1) Install dependencies
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then
  echo -e "${STY_BOLD}${STY_YELLOW}Installing dependencies...${STY_RST}"
  echo
  
  # Export variables needed by install-deps.sh
  export ask=$([[ "$MODE" == "manual" ]] && echo "true" || echo "false")
  export SKIP_SYSUPDATE=false
  export GPU_TYPE
  
  # Source the install-deps script (like end-4 does with ./setup install)
  if [[ -f "${BLOATER_ROOT}/bloat/deps/install-deps.sh" ]]; then
    source "${BLOATER_ROOT}/bloat/deps/install-deps.sh"
  else
    echo -e "${STY_RED}Error: install-deps.sh not found${STY_RST}"
    exit 1
  fi
  
  echo
  echo -e "${STY_GREEN}✓ Dependencies installed${STY_RST}"
  echo
fi # End of part 1

# ===========================================================
# 2) Initial Setup and Configurations
# ===========================================================
if [[ "$MODE" != "customize-only" ]]; then

# Add user to docker group (from bloater-system metapackage)
run_cmd "sudo usermod -aG docker ${TARGET_USER}"

# Install oh-my-zsh and set zsh as default shell
echo -e "${STY_CYAN}Setting up Zsh...${STY_RST}"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo -e "${STY_YELLOW}oh-my-zsh already installed, skipping...${STY_RST}"
else
  OHMYZSH_CMD="env RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL ${OHMYZSH_INSTALL_URL})\""
  run_cmd "$OHMYZSH_CMD"
fi

if [[ -z "$ZSH_PATH" ]]; then
  ZSH_PATH="$(command -v zsh || true)"
fi

if [[ -n "$ZSH_PATH" ]]; then
  CHSH_CMD="sudo chsh -s ${ZSH_PATH} ${TARGET_USER}"
  run_cmd "$CHSH_CMD"
else
  echo -e "${STY_RED}zsh not found; skipping chsh.${STY_RST}"
fi

# Enable and configure libvirt for virtualization
echo -e "${STY_CYAN}Configuring libvirt virtualization...${STY_RST}"
run_cmd "sudo systemctl enable --now libvirtd"
run_cmd "sudo usermod -aG libvirt,kvm ${TARGET_USER}"

# Load appropriate KVM module based on CPU type
echo -e "${STY_CYAN}Loading KVM kernel module...${STY_RST}"
if grep -q "GenuineIntel" /proc/cpuinfo; then
  KVM_MODULE_CMD="sudo modprobe kvm_intel"
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
  KVM_MODULE_CMD="sudo modprobe kvm_amd"
else
  echo -e "${STY_YELLOW}Unknown CPU vendor, skipping KVM module load${STY_RST}"
  KVM_MODULE_CMD=""
fi
if [[ -n "$KVM_MODULE_CMD" ]]; then
  run_cmd "$KVM_MODULE_CMD"
fi

# Configure Timeshift settings
echo -e "${STY_CYAN}Configuring Timeshift...${STY_RST}"
TIMESHIFT_CONFIG="/etc/timeshift/timeshift.json"
TIMESHIFT_DEFAULT="/etc/timeshift/default.json"

# Initialize config if needed
run_cmd "sudo bash -c '[ ! -f \"$TIMESHIFT_CONFIG\" ] || [ ! -s \"$TIMESHIFT_CONFIG\" ] && { [ -f \"$TIMESHIFT_DEFAULT\" ] && cp \"$TIMESHIFT_DEFAULT\" \"$TIMESHIFT_CONFIG\" || echo \"{}\" > \"$TIMESHIFT_CONFIG\"; } || true'"

# Configure Timeshift settings
run_cmd "sudo jq '.btrfs_mode = \"true\" | .include_btrfs_home_for_backup = \"true\" | .schedule_daily = \"true\" | .count_daily = \"5\" | .date_format = \"%Y-%m-%d %I:%M %p\"' \"$TIMESHIFT_CONFIG\" | sudo tee \"$TIMESHIFT_CONFIG.tmp\" > /dev/null && sudo mv \"$TIMESHIFT_CONFIG.tmp\" \"$TIMESHIFT_CONFIG\""

# Configure Discord to skip host updates
echo -e "${STY_CYAN}Configuring Discord settings...${STY_RST}"
DISCORD_SETTINGS="${XDG_CONFIG_HOME}/discord/settings.json"
run_cmd "mkdir -p \"${XDG_CONFIG_HOME}/discord\""

# Create or update Discord settings
if [[ -f "$DISCORD_SETTINGS" && -s "$DISCORD_SETTINGS" ]]; then
  # File exists and has content, append to existing JSON
  DISCORD_UPDATE_CMD="jq '. + {\"SKIP_HOST_UPDATE\": true, \"DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING\": true}' \"$DISCORD_SETTINGS\" > \"$DISCORD_SETTINGS.tmp\" && mv \"$DISCORD_SETTINGS.tmp\" \"$DISCORD_SETTINGS\""
else
  # File doesn't exist or is empty, create new JSON
  DISCORD_UPDATE_CMD="echo '{\"SKIP_HOST_UPDATE\": true, \"DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING\": true}' > \"$DISCORD_SETTINGS\""
fi
run_cmd "$DISCORD_UPDATE_CMD"

# Configure PAM for Hyprlock with fingerprint support
echo -e "${STY_CYAN}Configuring PAM for Hyprlock fingerprint authentication...${STY_RST}"
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

# Install VS Code ~~bloat~~ extensions
echo -e "${STY_CYAN}Installing VS Code extensions...${STY_RST}"
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

# Build command with all extensions
VSCODE_EXT_CMD="code"
for ext in "${VSCODE_EXTENSIONS[@]}"; do
  VSCODE_EXT_CMD="$VSCODE_EXT_CMD --install-extension ${ext}"
done
run_cmd "$VSCODE_EXT_CMD"

# Configure VS Code settings (theme and icons)
echo -e "${STY_CYAN}Configuring VS Code theme and icons...${STY_RST}"
VSCODE_SETTINGS_DIR="${XDG_CONFIG_HOME}/Code/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

run_cmd "mkdir -p \"$VSCODE_SETTINGS_DIR\""

# Update or create settings.json with theme preferences
VSCODE_THEME_CMD="jq '. + {\"workbench.colorTheme\": \"Material Theme Ocean\", \"workbench.iconTheme\": \"material-icon-theme\"}' \"$VSCODE_SETTINGS_FILE\" 2>/dev/null > \"$VSCODE_SETTINGS_FILE.tmp\" && mv \"$VSCODE_SETTINGS_FILE.tmp\" \"$VSCODE_SETTINGS_FILE\" || echo '{\"workbench.colorTheme\": \"Material Theme Ocean\", \"workbench.iconTheme\": \"material-icon-theme\"}' > \"$VSCODE_SETTINGS_FILE\""
run_cmd "$VSCODE_THEME_CMD"

# Remove unused display managers
echo -e "${STY_CYAN}Removing unused display managers (none look good)...${STY_RST}"
REMOVE_CMD="sudo pacman -Rns ${PACMAN_FLAGS} sddm gdm lightdm || true"
run_cmd "$REMOVE_CMD"

echo -e "${STY_BOLD}${STY_YELLOW}Installing bootup themes...${STY_RST}"

# Install CyberGRUB-2077 theme
echo -e "${STY_CYAN}Installing CyberGRUB-2077 theme...${STY_RST}"
GRUB_THEMES_DIR="/boot/grub/themes"
CYBERGRUB_THEME_DIR="${GRUB_THEMES_DIR}/CyberGRUB-2077"

# Create themes directory if it doesn't exist
run_cmd "sudo mkdir -p \"${GRUB_THEMES_DIR}\""

# Copy theme files from bloat/themes
run_cmd "sudo cp -r \"${BLOATER_ROOT}/bloat/themes/CyberGRUB-2077\" \"${GRUB_THEMES_DIR}/\""

# Update GRUB config to use the theme
GRUB_CFG="/etc/default/grub"
GRUB_THEME_LINE="GRUB_THEME=\"${CYBERGRUB_THEME_DIR}/theme.txt\""
run_cmd "if sudo grep -qE '^#?GRUB_THEME=' \"${GRUB_CFG}\"; then sudo sed -i -E 's|^#?GRUB_THEME=.*|${GRUB_THEME_LINE}|' \"${GRUB_CFG}\"; else echo '${GRUB_THEME_LINE}' | sudo tee -a \"${GRUB_CFG}\" > /dev/null; fi"

# Add splash to GRUB_CMDLINE_LINUX_DEFAULT if not present
run_cmd "if ! sudo grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=.*splash' \"${GRUB_CFG}\" >/dev/null 2>&1; then sudo sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)(\")/\\1 splash\\2/' \"${GRUB_CFG}\"; fi"

# Update GRUB
run_cmd "sudo grub-mkconfig -o /boot/grub/grub.cfg"

# Add plymouth to mkinitcpio.conf HOOKS
echo -e "${STY_CYAN}Adding plymouth to mkinitcpio.conf...${STY_RST}"
MKINIT_PLYMOUTH_CMD="if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then sudo sed -i 's/^HOOKS=\(.*\)\(base udev\)/HOOKS=\\1\\2 plymouth/' /etc/mkinitcpio.conf || sudo sed -i 's/^HOOKS=\(.*\)\(systemd\)/HOOKS=\\1\\2 plymouth/' /etc/mkinitcpio.conf; else echo 'plymouth already in HOOKS, skipping...'; fi"
run_cmd "$MKINIT_PLYMOUTH_CMD"

# Install chika Plymouth theme
echo -e "${STY_CYAN}Installing chika Plymouth theme...${STY_RST}"
PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"
run_cmd "sudo mkdir -p \"${PLYMOUTH_THEMES_DIR}/chika\""
run_cmd "sudo cp -r \"${BLOATER_ROOT}/bloat/themes/chika\"/* \"${PLYMOUTH_THEMES_DIR}/chika/\""
run_cmd "sudo plymouth-set-default-theme -R chika"
fi # End of part 3

# ===========================================================
# 4) Apply customizations
# ===========================================================
echo -e "${STY_BOLD}${STY_YELLOW}Applying the secret sauce...${STY_RST}"

# Copy .zshrc
echo -e "${STY_CYAN}Copying custom .zshrc...${STY_RST}"
if [[ -f "$HOME/.zshrc" ]]; then
  echo -e "${STY_YELLOW}Backing up existing .zshrc to .zshrc.backup.$(date +%Y%m%d_%H%M%S)${STY_RST}"
  run_cmd "cp \"$HOME/.zshrc\" \"$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)\""
fi
run_cmd "cp -f \"${BLOATER_ROOT}/bloat/dots/.zshrc\" \"$HOME/\""

# Copy wallpaper directory
echo -e "${STY_CYAN}Copying wallpaper directory...${STY_RST}"
run_cmd "mkdir -p \"$HOME/Wallpapers\""
run_cmd "cp -r \"${BLOATER_ROOT}/bloat/wallpaper\"/* \"$HOME/Wallpapers/\""

# Set initial wallpaper
echo -e "${STY_CYAN}Setting initial wallpaper...${STY_RST}"
run_cmd "bash -c '~/.config/quickshell/ii/scripts/colors/switchwall.sh ~/Wallpapers/Kayoko.jpg & WALLPAPER_PID=\$!; sleep 10; kill \$WALLPAPER_PID 2>/dev/null; pkill -P \$WALLPAPER_PID 2>/dev/null; exit 0' || true"

# Copy illogical-impulse config
echo -e "${STY_CYAN}Copying custom illogical-impulse config...${STY_RST}"
II_CONFIG_DIR="${XDG_CONFIG_HOME}/illogical-impulse"
run_cmd "cp -f \"${BLOATER_ROOT}/bloat/dots/.config/illogical-impulse/config.json\" \"$II_CONFIG_DIR/\""

# Update wallpaper path to current user
echo -e "${STY_CYAN}Updating wallpaper path for current user...${STY_RST}"
run_cmd "sed -i 's|/home/[^/]*/Wallpapers/|/home/'\"$TARGET_USER\"'/Wallpapers/|g' \"$II_CONFIG_DIR/config.json\""

# Monitor config
echo -e "${STY_CYAN}Configuring monitor settings...${STY_RST}"
HYPR_CONF_FILE="${XDG_CONFIG_HOME}/hypr/monitors.conf"

# Create monitors.conf with all settings if it doesn't exist or is missing configurations
run_cmd "if ! grep -q 'monitor = , preferred, auto, 1.333334' \"$HYPR_CONF_FILE\" 2>/dev/null; then echo 'monitor = , preferred, auto, 1.333334' >> \"$HYPR_CONF_FILE\"; fi"
run_cmd "if ! grep -q 'force_zero_scaling' \"$HYPR_CONF_FILE\" 2>/dev/null; then printf '\\nxwayland {\\n  force_zero_scaling = true\\n}\\n' >> \"$HYPR_CONF_FILE\"; fi"
run_cmd "if ! grep -q 'env = GDK_SCALE' \"$HYPR_CONF_FILE\" 2>/dev/null; then echo 'env = GDK_SCALE,2' >> \"$HYPR_CONF_FILE\"; fi"
run_cmd "if ! grep -q 'env = XCURSOR_SIZE' \"$HYPR_CONF_FILE\" 2>/dev/null; then echo 'env = XCURSOR_SIZE,32' >> \"$HYPR_CONF_FILE\"; fi"

# Modify Kitty to use zsh
echo -e "${STY_CYAN}Updating Kitty terminal to use Zsh...${STY_RST}"
KITTY_FILE="${XDG_CONFIG_HOME}/kitty/kitty.conf"
run_cmd "if grep -q '^shell fish' \"$KITTY_FILE\" 2>/dev/null; then sed -i 's/^shell fish/# shell fish\\n\\n# Use zsh\\nshell zsh/' \"$KITTY_FILE\"; elif ! grep -q '^shell zsh' \"$KITTY_FILE\" 2>/dev/null; then echo 'shell zsh' >> \"$KITTY_FILE\"; fi"

# Modify Hyprland keybinds to add Vivaldi
echo -e "${STY_CYAN}Prioritizing Vivaldi in keybinds...${STY_RST}"
HYPR_KEYBINDS_FILE="${XDG_CONFIG_HOME}/hypr/hyprland/keybinds.conf"
run_cmd "if grep -q 'launch_first_available.sh.*Browser' \"$HYPR_KEYBINDS_FILE\" 2>/dev/null && ! grep -q '\\\"vivaldi\\\"' \"$HYPR_KEYBINDS_FILE\" 2>/dev/null; then sed -i 's|bind = Super, W, exec, ~/.config/hypr/hyprland/scripts/launch_first_available.sh \\\"google-chrome-stable\\\" \\\"zen-browser\\\" \\\"firefox\\\" \\\"brave\\\" \\\"chromium\\\" \\\"microsoft-edge-stable\\\" \\\"opera\\\" \\\"librewolf\\\" # Browser|bind = Super, W, exec, ~/.config/hypr/hyprland/scripts/launch_first_available.sh \\\"vivaldi\\\" \\\"google-chrome-stable\\\" \\\"zen-browser\\\" \\\"firefox\\\" \\\"brave\\\" \\\"chromium\\\" \\\"microsoft-edge-stable\\\" \\\"opera\\\" \\\"librewolf\\\" # Browser|' \"$HYPR_KEYBINDS_FILE\"; fi"

# Copy Hyprlock helper script
echo -e "${STY_CYAN}Copying Hyprlock helper script...${STY_RST}"
HYPRLOCK_DIR="${XDG_CONFIG_HOME}/hypr/hyprlock"
run_cmd "mkdir -p \"$HYPRLOCK_DIR\""
run_cmd "cp -f \"${BLOATER_ROOT}/bloat/dots/.config/hypr/hyprlock/get_wallpaper_path.sh\" \"$HYPRLOCK_DIR/\""

# Copy custom Hyprlock config
echo -e "${STY_CYAN}Copying custom Hyprlock config...${STY_RST}"
HYPRLOCK_CONF="${XDG_CONFIG_HOME}/hypr/hyprlock.conf"
if [[ -f "$HYPRLOCK_CONF" ]]; then
  echo -e "${STY_YELLOW}Backing up existing hyprlock.conf to hyprlock.conf.backup.$(date +%Y%m%d_%H%M%S)${STY_RST}"
  run_cmd "cp \"$HYPRLOCK_CONF\" \"$HYPRLOCK_CONF.backup.$(date +%Y%m%d_%H%M%S)\""
fi
run_cmd "cp -f \"${BLOATER_ROOT}/bloat/dots/.config/hypr/hyprlock.conf\" \"$HYPRLOCK_CONF\""

# ===========================================================
# Add your own customizations here!
# Use run_cmd for any modifications you want to persist
# ===========================================================

echo -e "${STY_GREEN}✓ Customizations applied!${STY_RST}"
# End of part 4

echo
echo -e "${STY_BOLD}${STY_GREEN}Bloating complete! Your system is now beautifully bloated.${STY_RST}"
echo -e "${STY_BLUE}Mode:${STY_RST} ${STY_YELLOW}$MODE${STY_RST}"
if [[ "$MODE" != "customize-only" ]]; then
  if [[ "$GPU_TYPE" == "nvidia" ]]; then
    echo -e "${STY_YELLOW}Remember: You chose NVIDIA. May the driver gods be ever in your favor.${STY_RST}"
  elif [[ "$GPU_TYPE" == "skip" ]]; then
    echo -e "${STY_YELLOW}GPU drivers skipped. Don't forget to install them yourself!${STY_RST}"
  fi
fi
echo
echo -e "${STY_BOLD}${STY_CYAN}Time to reboot and enjoy your feature-packed monstrosity!${STY_RST}"
