# modules/nixos/profiles/workstation.nix
#
# Workstation profile for sloane: gaming, music production
# (Bitwig + LinnStrument + Kontakt-via-yabridge), 3D printing
# slicers, CAD, electronics.
#
# Composes the building-block modules and adds the user-facing
# applications. Daemons and hardware concerns live in their own
# modules under desktop/, hardware/, and services/.
#
# A future second workstation host could import this profile and
# get the same setup. The kid/family hosts will use a much smaller
# gaming-minimal profile instead.

{ pkgs, ... }:

{
  # ─── Composed modules ───────────────────────────────────────────────
  imports = [
    ../core/locale.nix
    ../core/networking.nix
    ../core/nix-settings.nix
    ../desktop/audio.nix
    ../desktop/fonts.nix
    ../desktop/login-manager.nix
    ../desktop/printing.nix
    ../desktop/theming.nix
    ../hardware/amd-gpu.nix
    ../hardware/bluetooth.nix
    ../hardware/intel-cpu.nix
    ../services/flatpak.nix
    ../services/fwupd.nix
    ../services/openssh.nix
  ];

  # ─── Module options ─────────────────────────────────────────────────
  # ROCm disabled until Blender returns or other GPU-compute use shows up.
  # AMD GPU graphics (Mesa/RADV/32-bit) stay enabled — that's the base
  # config of the amd-gpu module, this just controls the ROCm overlay.
  local.audio.lowLatency.enable        = true;
  local.networking.gamingTweaks.enable = true;
  local.hardware.amdGpu.rocm.enable    = false;

  # ─── Steam ──────────────────────────────────────────────────────────
  # Steam needs to be a NixOS program (not just a package) so NixOS
  # can set up the Steam runtime, firewall rules, and font packaging.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall      = true;
    dedicatedServer.openFirewall = true;
  };

  # Tell Steam where Proton-GE installs live (managed by protonplus).
  # Without this, custom Proton versions show up as missing in
  # Steam's compatibility tool list.
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };

  # ─── Gaming runtime ─────────────────────────────────────────────────
  # gamemode: kernel scheduling tweaks during gameplay (CPU
  # governor → performance, IO priority bumps). Used via
  # `gamemoderun %command%` in Steam launch options.
  programs.gamemode.enable = true;

  # ─── Shell ──────────────────────────────────────────────────────────
  # System-level fish setup. Installs fish, registers it in
  # /etc/shells (so users.users.<x>.shell = pkgs.fish works), and
  # sets up vendor-provided completions for system commands.
  # User-level fish config (prompt, aliases, abbreviations,
  # plugin manager) goes in home-manager when we wire that up.
  programs.fish.enable = true;

  # ─── Memory pressure relief ─────────────────────────────────────────
  # zram compresses inactive memory pages in RAM rather than writing
  # them to disk. Faster than disk swap, zero disk wear.
  # Default size = 50% of RAM (16GB on this 32GB system) — plenty.
  # Pairs with the small (8GB) disk swap defined in
  # hardware-configuration.nix as an OOM safety net.
  zramSwap.enable = true;

  # ─── Allow unfree packages ──────────────────────────────────────────
  # Bitwig, vesktop, Steam, Bambu Studio, Brave (BSD-3 with non-free
  # Widevine for DRM), etc. are non-free.
  nixpkgs.config.allowUnfree = true;

  # ─── Brave policies (de-bloat) ──────────────────────────────────────
  # Chrome Enterprise policies dropped into /etc/brave/policies/managed/
  # to disable Brave's bundled crypto/AI/VPN/news/tor features.
  # We keep Brave Sync enabled (the reason we want Brave alongside
  # Helium — its sync infrastructure works for cross-device tabs).
  # DnsOverHttpsMode = "off" defers DNS to the OS resolver, which goes
  # to the router and from there to NextDNS — keeping NextDNS in the
  # filtering path rather than letting Brave bypass it via DoH.
  #
  # Verify policies are applied after install: brave://policy/
  environment.etc."brave/policies/managed/policies.json".text = builtins.toJSON {
    BraveRewardsDisabled       = true;
    BraveWalletDisabled        = true;
    BraveVPNDisabled           = true;
    BraveAIChatEnabled         = false;
    BraveNewsDisabled          = true;
    BraveTalkDisabled          = true;
    TorDisabled                = true;
    BraveP3AEnabled            = false;
    BraveStatsPingEnabled      = false;
    BraveWebDiscoveryEnabled   = false;
    DnsOverHttpsMode           = "off";
  };

  # ─── PAM for Noctalia lock screen ───────────────────────────────────
  # Noctalia's lock screen authenticates via PAM. The package doesn't
  # install a PAM service entry — we provide one here. Empty config
  # body uses NixOS's default PAM template (login-equivalent auth).
  security.pam.services.noctalia-shell = {};

  # ─── User-facing applications ───────────────────────────────────────
  environment.systemPackages = with pkgs; [

    # System utilities
    wget
    fastfetch
    pciutils                       # lspci for hardware inspection
    vulkan-tools                   # vulkaninfo to verify GPU stack
    clinfo                         # OpenCL inspection
    rclone                         # Proton Drive sync (configured manually)

    # System / GPU monitoring
    btop                           # all-in-one TUI system monitor
    amdgpu_top                     # AMD-specific GPU detail

    # Browsers
    librewolf                      # primary browser (Firefox-based)
    brave                          # Chromium-based; debloated via policies above

    # Terminal
    ghostty

    # File management
    nautilus                       # GUI file manager
    file-roller                    # archive GUI for nautilus right-click

    # Image viewer / editor
    loupe                          # GTK4 viewer; handles crop/rotate/flip
    pinta                          # simple raster editor (resize, brightness, paint)

    # PDF viewer
    evince

    # Video
    showtime                       # GNOME video player (GStreamer)

    # Screenshots
    grim                           # Wayland screen capture
    slurp                          # region selector
    wl-clipboard                   # Wayland clipboard CLI
    satty                          # screenshot annotation

    # Gaming runtime extras
    mangohud                       # FPS / sensor overlay
    protonplus                     # manage Proton-GE versions
    adwsteamgtk                    # GTK theme for Steam
    winetricks                     # Windows dependency helper
    wineWow64Packages.stable       # 32+64-bit Wine

    # Audio: routing and control
    crosspipe                      # GTK4/Libadwaita PipeWire patchbay (helvum successor)
    pwvucontrol                    # GTK4 PipeWire-native per-app volume

    # Audio: instruments and processing
    surge-xt                       # synth (used with LinnStrument)
    zam-plugins                    # mixing/mastering plugin set

    # Audio: production
    bitwig-studio
    yabridge                       # Windows VST → Linux bridge
    yabridgectl                    # yabridge management CLI

    # 3D / Design / Creative
    freecad                        # parametric CAD

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
    proton-vpn
    proton-pass
    proton-authenticator

    # Communication
    signal-desktop
    vesktop                        # Discord client with native Wayland support
  ];
}
