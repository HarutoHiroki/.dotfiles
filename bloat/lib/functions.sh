# Helper functions for bloater
# Inspired by end-4/dots-hyprland functions.sh

# Execute command with optional logging
x() {
  "$@"
}

# Execute command with verbose output
v() {
  echo -e "${STY_BLUE}Running:${STY_RST} $*"
  "$@"
}

# Try to execute, don't fail if command fails
try() {
  "$@" || true
}

# Show function name being executed
showfun() {
  echo -e "${STY_CYAN}[Function]:${STY_RST} $1"
}

# Pause for user input
pause() {
  if [[ "${ask:-true}" == "true" ]]; then
    read -rp "Press Enter to continue..."
  fi
}

# Run command based on mode (following bloater's pattern)
run_cmd() {
  local cmd="$1"
  if [[ "${ask:-true}" == "true" ]]; then
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
  else
    echo -e "${STY_BLUE}[RUNNING]${STY_RST} $cmd"
    eval "$cmd"
  fi
}

# Check if running as root
prevent_sudo_or_root() {
  if [ "$EUID" -eq 0 ]; then
    echo -e "${STY_RED}Please do not run this script as root or with sudo${STY_RST}"
    exit 1
  fi
}

# Store PID in a global variable that can be accessed by trap
declare -g SUDO_KEEPALIVE_PID=""

# Initialize sudo session and keep it alive in background
sudo_init_keepalive() {
  # Check if sudo is available
  if ! command -v sudo >/dev/null 2>&1; then
    return 0
  fi

  # Skip if already initialized
  if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
    return 0
  fi

  # Prompt for sudo password once at the beginning
  echo -e "${STY_CYAN}[bloater]: Requesting sudo privileges for installation...${STY_RST}"
  if ! sudo -v; then
    echo -e "${STY_RED}[bloater]: Failed to obtain sudo privileges. Aborting...${STY_RST}"
    exit 1
  fi

  # Start background process to keep sudo session alive
  # This updates the sudo timestamp every 60 seconds
  (
    while true; do
      sleep 60
      sudo -v 2>/dev/null || exit 0
    done
  ) &
  SUDO_KEEPALIVE_PID=$!

  echo -e "${STY_GREEN}[bloater]: Sudo session initialized and will be kept alive (PID: $SUDO_KEEPALIVE_PID)${STY_RST}"
}

# Stop the sudo keepalive background process
sudo_stop_keepalive() {
  if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null
    SUDO_KEEPALIVE_PID=""
  fi
}
