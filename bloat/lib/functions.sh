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
