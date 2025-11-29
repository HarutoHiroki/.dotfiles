# Dotfiles (Now With Extra Bloat!)

## Introduction

This repository contains my personal dotfiles and an automated bloating script to quickly transform a fresh Arch Linux system into a beautiful, feature-packed monstrosity with my preferred configuration.

**Important:** These dotfiles are specifically designed as extra spice for [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (illogical-impulse quickshell dots). You **must** install end-4's beautiful base configuration first before unleashing this bloater upon your system.

## Prerequisites (The Boring Stuff You Can't Skip)

1. Install [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) following their installation instructions
2. Ensure the base configuration is working properly and looking gorgeous
3. Then run the bloater script to add approximately 67 gigabytes of "essential" packages

## The Bloater Script™

The `bloater.sh` (formerly known by its boring name `install.sh`) is designed for Arch Linux systems and automates the transformation of your lightweight system into a feature-complete powerhouse on top of the illogical impulse quickshell dots. It supports three flavors of chaos:
- **YOLO mode** (unattended): Runs all commands automatically with reckless abandon and `--noconfirm` flags
- **Paranoid mode** (manual): Prompts before each command because trust issues are valid
- **Diet mode** (customize-only): Only applies visual customizations, skipping the package avalanche

### What the Bloater Does (Buckle Up)

1. **System Configuration (The Foundation of Chaos)**
   - Enables multilib repository because we need 32-bit bloat too
   - Updates system packages (this might take a while, go make coffee)

2. **Package Installation (The Main Event)**
   - **Fonts**: Every Japanese font known to mankind (Adobe Source Han, Noto CJK, IPA, VLGothic, Jigmo) plus compatibility fonts for that one weird app
   - **Development**: Git (obviously), Zip, Seahorse (for when you forget your passwords)
   - **Power Management**: upower, acpid, powertop, power-profiles-daemon (laptop battery goes brrr)
   - **Browser**: Vivaldi because Chrome is too mainstream
   - **Security**: Fingerprint authentication (libfprint, fprintd) for that CSI: Cyber aesthetic
   - **Boot**: Plymouth splash screen (because plain text boot is for peasants)
   - **Shell**: Zsh and Oh My Zsh (fish is cool but we're rebels)
   - **Audio**: EasyEffects for that sweet, sweet audio processing
   - **Containers**: Docker (containerize all the things!)
   - **System Tools**: btop (htop but prettier), fastfetch (neofetch but faster)
   - **Graphics**: Complete AMD GPU stack (smooth sailing) or NVIDIA stack (good luck soldier) with 32-bit support
   - **Media**: mpv (the best video player, fight me), imv image viewer, fwupd for firmware shenanigans
   - **VPN**: OpenVPN with GUI, WireGuard (for totally legal purposes)
   - **Network Tools**: Nmap, Wireshark (definitely for educational purposes only)
   - **Gaming**: Wine, Lutris (Windows games on Linux, the ultimate flex)
   - **Flatpak**: Because sometimes you need extra sandboxes

3. **Shell Setup (Embrace the Zsh Life)**
   - Installs Oh My Zsh framework (because vanilla Zsh is lonely)
   - Sets Zsh as default shell (fish was never an option)

4. **AUR Packages (The Fun Stuff)**
   - WireGuard GUI (pretty VPN buttons)
   - Feishin (music streaming client for the audiophiles)
   - Steam gaming platform (because we "use Arch btw" for gaming)
   - ProtonUp-Qt (make Windows games work, it's basically magic)
   - Minecraft Launcher (don't judge)
   - Visual Studio Code (yes, the proprietary one, sue me)
   - Bottles (run Windows apps without the shame of dual-booting)

5. **Bootup Themes (Aesthetic Overload)**
   - Installs CyberGRUB-2077 GRUB theme (cyberpunk your bootloader)
   - Installs chika Plymouth theme (because the venn diagram between linux users and weebs is a circle)

6. **Desktop Customizations (The Secret Sauce)**
   - Copies custom `.zshrc` configuration (aliases upon aliases)
   - Configures Hyprland monitor settings with oddly specific 1.333334 scaling
   - Updates Kitty terminal to use Zsh instead of Fish (sorry fish fans)
   - Modifies Hyprland keybinds to prioritize Vivaldi browser (Chrome who?)
   - **Extensible**: Add your own ~~bloat~~ essential customizations in the marked section

7. **Cleanup (Taking Out the Trash)**
   - Removes unused display managers (SDDM, GDM, LightDM - we don't need you anymore)

### Usage (Time to Get Bloated)

```bash
./bloater.sh
```

The script will ask you two important life questions:
1. **Setup mode** (YOLO/unattended, paranoid/manual, or diet/customize-only)
2. **GPU type** (AMD master race or NVIDIA pain mode) - only if you chose full bloat mode

Or be a power user and specify options directly:
```bash
./bloater.sh unattended amd      # Full bloat: AMD GPU, hold my coffee
./bloater.sh manual nvidia       # Full bloat: NVIDIA GPU, prepare for driver hell
./bloater.sh customize-only      # Diet mode: just the pretty configs, hold the packages
GPU_TYPE=nvidia ./bloater.sh     # Full bloat: NVIDIA GPU, I also hate myself
```

### Diet Mode (Customize-Only)

If you've already bloated your system and just want the cosmetic tweaks, or if you:
- Want to re-apply customizations after updates to end-4's dots
- Want to test new configs without downloading the internet again
- Just installed a fresh end-4 dots and only want my visual tweaks

Use diet mode:
```bash
./bloater.sh customize-only
```

This mode skips the entire package avalanche (parts 1-5, 7) and only applies the part 6 customizations. Your disk space is safe... for now.

### Adding Your Own Bloat (I Mean, Customizations)

To add new customizations that will run in all modes (including diet mode):

1. Open `bloater.sh` in your favorite text editor
2. Navigate to **Part 6** (the customization zone)
3. Add your ~~bloat~~ essential tweaks using the `run_cmd` function

Example (totally necessary additions):
```bash
# Add that sick wallpaper you found on r/unixporn
run_cmd "cp -f wallpaper.jpg \"$HOME/.config/hypr/wallpaper.jpg\""

# Tweak configs to perfection
run_cmd "sed -i 's/old_value/new_value/' \"$HOME/.config/someapp/config.conf\""
```

All customizations will automatically respect your chosen mode (paranoid/YOLO) and prompt accordingly.

#### GPU Support (Team Red vs Team Green)

The bloater supports both AMD and NVIDIA graphics cards with their respective ~~bloat~~ driver stacks:

**AMD Stack (The Open Source Champions):**
- Mesa (OpenGL/Vulkan drivers that actually work out of the box)
- VDPAU (hardware video acceleration without selling your soul)
- Vulkan-radeon (ray tracing without proprietary shackles)
- 32-bit library support (seamless gaming experience)
- Wayland support that doesn't make you want to cry

**NVIDIA Stack (The Proprietary Overlords - Abandon Hope All Ye Who Enter Here):**
- NVIDIA proprietary drivers ([Linus has opinions](https://www.youtube.com/watch?v=_36yNWw_07g) about these)
- NVIDIA-utils and settings (because nothing can be simple)
- Vulkan support (DLSS goes brrr when it works)
- 32-bit library support (also for gaming, when the stars align)
- Wayland "support" (good luck with that screen sharing and suspend/resume)
- Kernel module signing headaches (SecureBoot says hello)
- Breaking with every kernel update (dkms is your frenemy now)
- That one bug that's been open for 3 years

*Note to NVIDIA users: We support your GPU but question your life choices. Consider switching to AMD for your sanity.*

**Note:** This bloater is specifically designed for Arch Linux with Hyprland. Review the script before unleashing it upon your system to ensure you actually want all this stuff. No refunds on disk space.
