# Environment variables for bloater

# Color codes for output
STY_RED='\033[0;31m'
STY_GREEN='\033[0;32m'
STY_YELLOW='\033[0;33m'
STY_BLUE='\033[0;34m'
STY_CYAN='\033[0;36m'
STY_BOLD='\033[1m'
STY_RST='\033[0m'

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# Bloater-specific variables
export BLOATER_ROOT="${BLOATER_ROOT:-$(pwd)}"
export BLOATER_BACKUP_DIR="${BLOATER_BACKUP_DIR:-$HOME/bloater-original-backup}"
export BLOATER_CACHE_DIR="${BLOATER_ROOT}/cache"
