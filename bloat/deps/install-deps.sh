# This script is meant to be sourced, not run directly
# Inspired by end-4/dots-hyprland install-deps.sh

# Install yay if not present
install-yay() {
  v sudo pacman -S --needed --noconfirm base-devel git
  x git clone https://aur.archlinux.org/yay-bin.git /tmp/buildyay
  x cd /tmp/buildyay
  x makepkg -o
  x makepkg -se
  x makepkg -i --noconfirm
  x cd "${BLOATER_ROOT}"
  rm -rf /tmp/buildyay
}

# Install a local PKGBUILD
# Sourced from end-4/dots-hyprland install-deps.sh
install-local-pkgbuild() {
  local location=$1
  local installflags=$2
  
  x pushd "$location"
  
  source ./PKGBUILD
  x yay -S --sudoloop $installflags --asdeps "${depends[@]}"
  
  # Build and install the metapackage
  # -A: Ignore incomplete arch field
  # -f: Force build
  # -s: Install missing dependencies
  # -i: Install after build
  x makepkg -Afsi --noconfirm
  x popd
}

#####################################################################################
# Main installation logic
#####################################################################################

if ! command -v pacman >/dev/null 2>&1; then
  printf "${STY_RED}[bloater]: pacman not found, this script requires Arch Linux.${STY_RST}\\n"
  exit 1
fi

# Enable multilib
enable_multilib() {
  local pacman_conf="/etc/pacman.conf"
  if sudo grep -qE '^[[:space:]]*\\[multilib\\]' "$pacman_conf"; then
    echo "multilib already enabled"
    return 0
  fi

  echo "Enabling multilib"
  if sudo sed -n '/#\\[multilib\\]/,/#Include = \\/etc\\/pacman.d\\/mirrorlist/ p' "$pacman_conf" | grep -q '\\[multilib\\]'; then
    sudo sed -i '/#\\[multilib\\]/,/#Include = \\/etc\\/pacman.d\\/mirrorlist/ s/^#//' "$pacman_conf"
  else
    sudo bash -c "cat >>$pacman_conf <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF"
  fi

  echo "Refreshing pacman DB..."
  v sudo pacman -Syy
}

showfun enable_multilib
v enable_multilib

# System update (unless skipped)
case $SKIP_SYSUPDATE in
  true) 
    echo "Skipping system update"
    ;;
  *)
    showfun "System update"
    v sudo pacman -Syu
    ;;
esac

# Install yay if not present
if ! command -v yay >/dev/null 2>&1; then
  echo -e "${STY_YELLOW}[bloater]: 'yay' not found.${STY_RST}"
  showfun install-yay
  v install-yay
fi

# Define metapackages to install (like end-4's metapkgs array)
metapkgs=(
  "${BLOATER_ROOT}/bloat/deps/fonts"
  "${BLOATER_ROOT}/bloat/deps/development"
  "${BLOATER_ROOT}/bloat/deps/audio"
  "${BLOATER_ROOT}/bloat/deps/browser"
  "${BLOATER_ROOT}/bloat/deps/containers"
  "${BLOATER_ROOT}/bloat/deps/media"
  "${BLOATER_ROOT}/bloat/deps/network"
  "${BLOATER_ROOT}/bloat/deps/power"
  "${BLOATER_ROOT}/bloat/deps/security"
  "${BLOATER_ROOT}/bloat/deps/shell"
  "${BLOATER_ROOT}/bloat/deps/monitoring"
  "${BLOATER_ROOT}/bloat/deps/gaming"
)

# Add GPU-specific package
if [[ "$GPU_TYPE" == "amd" ]]; then
  metapkgs+=("${BLOATER_ROOT}/bloat/deps/gpu-amd")
elif [[ "$GPU_TYPE" == "nvidia" ]]; then
  metapkgs+=("${BLOATER_ROOT}/bloat/deps/gpu-nvidia")
fi

# Install each metapackage
for i in "${metapkgs[@]}"; do
  metainstallflags="--needed"
  $ask && showfun install-local-pkgbuild || metainstallflags="$metainstallflags --noconfirm"
  v install-local-pkgbuild "$i" "$metainstallflags"
done

echo -e "${STY_GREEN}✓ All bloater dependencies installed!${STY_RST}"
