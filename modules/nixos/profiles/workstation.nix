# modules/nixos/profiles/workstation.nix
#
# Workstation profile for sloane: gaming, music production
# (Bitwig + LinnStrument + Kontakt-via-yabridge), 3D printing
# slicers, CAD, Blender, electronics.
#
# Composes the building-block modules and adds the user-facing
# applications (browsers, DAWs, slicers, plugins, communication,
# media). Daemons and hardware concerns live in their own modules
# under desktop/, hardware/, and services/.
#
# A future second workstation host could import this profile and
# get the same setup. The kid/family hosts will use a much smaller
# gaming-minimal profile instead.

{ pkgs, ... }:

{
  # ─── Composed modules ───────────────────────────────────────────────
  # Everything sloane wants. Hosts that import this profile get the
  # whole stack; hosts that want a subset import the modules
  # individually.
  imports = [
    ../core/locale.nix
    ../core/networking.nix
    ../core/nix-settings.nix
    ../desktop/audio.nix
    ../desktop/fonts.nix
    ../desktop/printing.nix
    ../hardware/amd-gpu.nix
    ../hardware/bluetooth.nix
    ../hardware/intel-cpu.nix
    ../services/flatpak.nix
    ../services/fwupd.nix
  ];

  # ─── Module options ─────────────────────────────────────────────────
  # Opt this profile into the modules that need a flag.
  local.audio.lowLatency.enable        = true;
  local.networking.gamingTweaks.enable = true;
  local.hardware.amdGpu.rocm.enable    = true;

  # ─── Steam ──────────────────────────────────────────────────────────
  # Steam needs to be a NixOS program (not just a package) so that
  # NixOS can set up the Steam runtime, network firewall rules,
  # and font packaging properly.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall      = true;
    dedicatedServer.openFirewall = true;
  };

  # Tell Steam where to find Proton-GE installs (managed via
  # protonup-qt below). Without this, custom Proton versions
  # show up as "missing" in Steam's compatibility tool list.
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };

  # ─── Gaming runtime tools ───────────────────────────────────────────
  # gamemode: kernel scheduling tweaks during gameplay (CPU
  # governor → performance, IO priority bumps). Used via
  # `gamemoderun %command%` in Steam launch options.
  programs.gamemode.enable = true;

  # gamescope: micro-compositor for game scaling. Useful for
  # forcing resolution/refresh independent of desktop, fixing
  # broken-resolution games, and consistent HDR handling.
  programs.gamescope.enable = true;

  # ─── Allow unfree packages ──────────────────────────────────────────
  # Bitwig, Discord, Steam, Bambu Studio etc. are non-free.
  nixpkgs.config.allowUnfree = true;

  # ─── User-facing applications ───────────────────────────────────────
  environment.systemPackages = with pkgs; [

    # System utilities
    wget
    neovim
    fastfetch
    pciutils                       # lspci for hardware inspection
    vulkan-tools                   # vulkaninfo to verify GPU stack
    vulkan-loader                  # ensure Vulkan loader present
    mesa-demos                     # glxinfo / glxgears
    clinfo                         # OpenCL inspection

    # System / GPU monitoring
    btop                           # all-in-one TUI system monitor
    amdgpu_top                     # AMD-specific GPU detail

    # Browsers
    librewolf

    # Terminal
    ghostty

    # File management
    nautilus                       # GUI file manager
    yazi                           # TUI file manager
    file-roller                    # archive GUI for nautilus right-click

    # Image viewer
    loupe

    # PDF viewer
    evince

    # Video
    vlc
    mpv

    # Screenshots (Niri keybindings will invoke these)
    grim                           # Wayland screen capture
    slurp                          # region selector
    wl-clipboard                   # Wayland clipboard CLI
    satty                          # screenshot annotation

    # Gaming runtime extras
    mangohud                       # FPS / sensor overlay
    protonup-qt                    # manage Proton-GE versions
    adwsteamgtk                    # GTK theme for Steam
    winetricks                     # Windows dependency helper
    wineWowPackages.stable         # 32+64-bit Wine for compat
    dxvk                           # DirectX 9/10/11 → Vulkan
    vkd3d-proton                   # DirectX 12 → Vulkan

    # Audio: routing and control
    qpwgraph                       # PipeWire patchbay
    pavucontrol                    # per-app volume

    # MIDI
    kmidimon                       # MIDI traffic monitor (LinnStrument debug)

    # Audio: instruments and processing
    surge-xt                       # synth (used with LinnStrument)
    zam-plugins                    # mixing/mastering plugin set

    # Audio: utilities and bridging
    ffmpeg
    sox
    yabridge                       # Windows VST → Linux bridge
    yabridgectl                    # yabridge management CLI

    # 3D / Design / Creative
    blender                        # GPU-accelerated via ROCm (enabled above)
    gimp
    krita
    freecad

    # Electronics
    arduino-ide

    # 3D printing
    bambu-studio
    orca-slicer
    # Lychee Slicer is installed via Flatpak (services/flatpak.nix)

    # Productivity
    standardnotes
    qalculate-gtk

    # Proton suite
    protonmail-desktop
    proton-vpn-gtk-app
    proton-pass
    proton-authenticator

    # Communication
    signal-desktop
    vesktop                        # Discord client with native Wayland support
  ];
}
