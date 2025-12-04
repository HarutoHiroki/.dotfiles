# Bloater Dependencies

This directory contains metapackages that organize all the software installed by bloater. Each category is a separate PKGBUILD that installs related packages.

## Categories

### Audio

- **easyeffects** - Advanced audio effects processor for PipeWire
- **feishin** - Modern music streaming client

### Browser

- **vivaldi** - Feature-rich Chromium-based web browser with extensive customization

### Containers

- **bottles** - Wine prefix manager for running Windows applications
- **docker** - Container platform for building and running applications
- **flatpak** - Universal package manager for Linux applications
- **flatpak-kcm** - KDE System Settings module for Flatpak

### Development

- **git** - Distributed version control system
- **seahorse** - GNOME keyring manager for passwords and encryption keys
- **visual-studio-code-bin** - Microsoft's code editor (binary from AUR)
- **zip** - Archive compression utility

### Fonts

Japanese fonts and compatibility fonts for proper character rendering.

- **adobe-source-han-sans-jp-fonts** - Adobe's Japanese sans-serif font family
- **adobe-source-han-serif-jp-fonts** - Adobe's Japanese serif font family
- **cantarell-fonts** - GNOME's default UI font
- **noto-fonts-cjk** - Google's CJK (Chinese, Japanese, Korean) font family
- **otf-ipaexfont** - Japanese TrueType fonts
- **ttf-dejavu** - High-quality derivative of Bitstream Vera fonts
- **ttf-jigmo** - Japanese monospace font
- **ttf-vlgothic** - Japanese TrueType font

### Gaming

- **lutris** - Open source gaming platform for managing game installations
- **minecraft-launcher** - Official Minecraft launcher
- **protonup-qt** - GUI tool for installing and managing Proton-GE versions
- **steam** - Valve's digital distribution platform
- **wine** - Windows compatibility layer for running Windows applications

### GPU - AMD

Open source AMD GPU drivers and libraries.

- **glu** - OpenGL utility library
- **lib32-glu** - 32-bit OpenGL utility library for compatibility
- **lib32-mesa** - 32-bit Mesa 3D graphics library
- **lib32-mesa-vdpau** - 32-bit VDPAU video acceleration
- **lib32-vulkan-radeon** - 32-bit Vulkan driver for AMD GPUs
- **mesa** - Open source OpenGL implementation
- **mesa-vdpau** - VDPAU video acceleration for Mesa
- **vulkan-icd-loader** - Vulkan Installable Client Driver loader
- **lib32-vulkan-icd-loader** - 32-bit Vulkan ICD loader
- **vulkan-radeon** - Vulkan driver for AMD GPUs

### GPU - NVIDIA

Proprietary NVIDIA GPU drivers and libraries.

- **glu** - OpenGL utility library
- **lib32-glu** - 32-bit OpenGL utility library
- **lib32-nvidia-utils** - 32-bit NVIDIA utilities for compatibility
- **lib32-vulkan-icd-loader** - 32-bit Vulkan ICD loader
- **nvidia** - NVIDIA proprietary kernel module
- **nvidia-settings** - NVIDIA driver control panel
- **nvidia-utils** - NVIDIA utilities and libraries
- **vulkan-icd-loader** - Vulkan Installable Client Driver loader

### Media

- **fwupd** - Firmware update daemon for Linux
- **imv** - Lightweight image viewer for Wayland and X11
- **mpv** - Versatile command-line media player

### Monitoring

- **btop** - Beautiful terminal-based resource monitor
- **fastfetch** - Fast system information tool (neofetch replacement)

### Network

Networking tools and VPN support.

- **networkmanager-openvpn** - NetworkManager plugin for OpenVPN
- **nmap** - Network discovery and security auditing tool
- **openvpn** - Open source VPN solution
- **wireshark-cli** - Command-line network protocol analyzer
- **wireshark-qt** - GUI network protocol analyzer
- **wireguard-tools** - Fast, modern, secure VPN tunnel

### Power

Power management and monitoring tools.

- **acpid** - ACPI event daemon for handling power events
- **power-profiles-daemon** - D-Bus daemon for power profile management
- **powertop** - Power consumption monitoring and tuning tool
- **upower** - Abstraction for power device enumeration

### Security

Authentication and boot security.

- **fprintd** - D-Bus service for fingerprint reader access
- **libfprint** - Library for fingerprint reader support
- **plymouth** - Boot splash screen manager
- **xorg-xhost** - Server access control program for X

### Shell
- **zsh** - Powerful shell with advanced features and customization

### Virtualization

Complete QEMU/KVM virtualization stack.

- **qemu-full** - Full QEMU system emulator with all architectures
- **libvirt** - API for managing virtualization platforms
- **virt-manager** - GUI for managing virtual machines
- **virt-viewer** - Display viewer for virtual machines
- **spice-vdagent** - SPICE agent for enhanced VM interaction
- **edk2-ovmf** - UEFI firmware for virtual machines
- **dnsmasq** - Lightweight DNS/DHCP server for VM networking
- **iptables-nft** - Linux firewall using nftables backend (replaces iptables)
- **bridge-utils** - Utilities for configuring network bridges

## Installation

These packages are automatically installed by the main `bloater.sh` script. The installation is handled by `install-deps.sh`, which:

1. Enables multilib repository for 32-bit library support
2. Installs `yay` AUR helper if not present
3. Installs each metapackage based on selected options
4. Handles GPU-specific packages based on user selection

## Adding New Packages

To add a new package:

1. Navigate to the appropriate category directory
2. Edit the `PKGBUILD` file
3. Add the package name to the `depends` array
4. Update this README with the package name and description
