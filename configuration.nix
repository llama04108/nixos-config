# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Home Manager NixOS module.
      <home-manager/nixos>
    ];

  # ── Bootloader ────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Kernel ────────────────────────────────────────────────────────────
  # Latest kernel with gaming-relevant parameters.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "quiet"
    "splash"
    "amdgpu.ppfeaturemask=0xffffffff"  # Unlocks all RX 7800 XT power features for LACT
    "amd_pstate=active"                # Better CPU power management
  ];

  # Silence kernel log spam on boot.
  boot.consoleLogLevel = 3;

  # ── LUKS Encryption ───────────────────────────────────────────────────
  boot.initrd.luks.devices."luks-40927fae-e8ca-4304-8c9d-f08684b6cb57".device =
    "/dev/disk/by-uuid/40927fae-e8ca-4304-8c9d-f08684b6cb57";

  # ── CPU ───────────────────────────────────────────────────────────────
  # Intel microcode updates — important for i5-14600K security patches.
  hardware.cpu.intel.updateMicrocode = true;

  # schedutil governor works well with the i5-14600K's hybrid core layout.
  powerManagement.cpuFreqGovernor = "schedutil";

  # ── GPU ───────────────────────────────────────────────────────────────
  # Load amdgpu early for faster boot and no flicker.
  hardware.amdgpu.initrd.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # Required for Steam/Proton/Wine
    extraPackages = with pkgs; [
      rocmPackages.clr.icd  # OpenCL support
    ];
  };

  # ROCm symlink — required for Blender GPU rendering and other HIP apps.
  systemd.tmpfiles.rules = let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [ rocblas hipblas clr ];
    };
  in [ "L+ /opt/rocm - - - - ${rocmEnv}" ];

  # Force Mesa RADV Vulkan driver — better game compatibility than AMDVLK.
  # AMDVLK is being discontinued anyway.
  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
    RADV_PERFTEST  = "gpl";  # Faster shader compilation, reduces stutter
    DXVK_ASYNC     = "1";    # Async shader compilation in DXVK
  };

  # ── Networking ────────────────────────────────────────────────────────
  networking.hostName = "sloane";
  networking.networkmanager.enable = true;

  # Prevent NetworkManager from overriding NextDNS.
  networking.networkmanager.dns = "none";

  # Gaming-relevant network and memory tweaks.
  boot.kernel.sysctl = {
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_fastopen"       = 3;
    "vm.swappiness"               = 10;  # Keep games in RAM, reduce swapping
    "vm.dirty_ratio"              = 6;
    "vm.dirty_background_ratio"   = 3;
  };

  # ── Bluetooth ─────────────────────────────────────────────────────────
  # Also enables Bluetooth MIDI controllers.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # ── Storage ───────────────────────────────────────────────────────────
  # Games SSD — separate 2TB Samsung SATA SSD.
  fileSystems."/games" = {
    device = "/dev/disk/by-uuid/a0665c14-cbcb-4904-8938-c378f5d4b4b3";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];  # nofail prevents boot issues if drive is missing
  };

  # ── Time & Locale ─────────────────────────────────────────────────────
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT    = "en_US.UTF-8";
    LC_MONETARY       = "en_US.UTF-8";
    LC_NAME           = "en_US.UTF-8";
    LC_NUMERIC        = "en_US.UTF-8";
    LC_PAPER          = "en_US.UTF-8";
    LC_TELEPHONE      = "en_US.UTF-8";
    LC_TIME           = "en_US.UTF-8";
  };

  # ── Input ─────────────────────────────────────────────────────────────
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # ── Users ─────────────────────────────────────────────────────────────
  users.users.matthew = {
    isNormalUser = true;
    description = "Matthew";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"    # MIDI and real-time audio device access
      "realtime" # Real-time scheduling priority
    ];
    packages = with pkgs; [];
  };

  # ── Packages ──────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # System tools
    wget
    nano
    neovim
    git                 # version control — configured via Home Manager below
    fastfetch
    nextdns             # DNS CLI — needed for 'nextdns status' and manual control
    pciutils            # lspci — useful for hardware debugging
    vulkan-tools        # vulkaninfo — verify Vulkan setup
    vulkan-loader       # ensure Vulkan loader is present
    mesa-demos          # glxinfo/glxgears for testing graphics
    clinfo              # verify OpenCL setup
    nvtopPackages.amd   # GPU monitoring in terminal

    # Browsers
    librewolf
    chromium

    # Gaming
    mangohud            # FPS/GPU/CPU overlay
    protonplus          # Manage Proton-GE versions
    adwsteamgtk         # Steam GTK theme
    lutris              # Non-Steam game launcher
    heroic              # Epic/GOG launcher
    bottles             # Windows app/game runner
    winetricks          # Windows game dependency helper
    wine                # Required by Lutris for some games
    dxvk                # DirectX → Vulkan translation
    vkd3d-proton        # DirectX 12 → Vulkan

    # Audio routing and monitoring
    qpwgraph            # PipeWire/JACK patchbay — essential for routing in Reaper
    pavucontrol         # PulseAudio/Pipewire volume control GUI
    carla               # Plugin host — run VSTs/LV2s standalone or as plugins

    # MIDI utilities
    a2jmidid            # ALSA to JACK MIDI bridge — some apps need this
    qmidinet            # Network MIDI — useful for routing MIDI between apps
    kmidimon            # MIDI monitor — see exactly what your controller is sending

    # Plugin formats and support
    ladspa-sdk          # LADSPA plugin support
    lv2                 # LV2 plugin support (best Linux-native format)

    # Plugins and instruments
    helm                # Polyphonic synth (LV2/VST) — unmaintained but still functional
    distrho-ports       # Large collection of ported VST/LV2 plugins
    zam-plugins         # EQ, compressor, limiter plugins
    dragonfly-reverb    # High quality reverb plugins
    calf                # Studio-quality effects (EQ, compressor, etc)
    surge-xt            # Synth with Linnstrument settings

    # Audio utilities
    ffmpeg              # Audio/video conversion, Reaper uses this
    sox                 # Command-line audio processing
    reaper              # Digital Audio Workstation

    # Windows VST bridging
    yabridge            # Bridges Windows VST2/VST3 plugins to Linux
    yabridgectl         # CLI tool to manage yabridge

    # 3D / Design / Creative
    pkgsRocm.blender    # 3D creation — built with ROCm/HIP support for RX 7800 XT GPU rendering
    gimp                # Image editor
    krita               # Digital painting and illustration
    freecad             # Parametric 3D CAD modeller

    # Electronics
    arduino-ide         # Arduino IDE for microcontroller programming

    # 3D Printing
    bambu-studio        # Bambu Lab slicer — note: cloud login may crash, use Flatpak if needed

    # Productivity
    standardnotes
    libreoffice
    qalculate-gtk       # RPN calculator with unit conversions and physical constants

    # Proton suite
    protonmail-desktop
    proton-vpn
    proton-vpn-cli
    proton-pass
    proton-pass-cli
    proton-authenticator

    # Communication
    signal-desktop
    discord

    # Media
    vlc
  ];

  # Point Steam to custom Proton-GE installs.
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };

  # ── Home Manager ──────────────────────────────────────────────────────
  # Manages user environment and dotfiles declaratively.
  # Run 'sudo nixos-rebuild switch' to apply changes — no separate
  # 'home-manager switch' command needed with this setup.
  home-manager.useGlobalPkgs   = true;  # Use system nixpkgs
  home-manager.useUserPackages = true;  # Install packages to user profile

  home-manager.users.matthew = { pkgs, ... }: {
    home.stateVersion = "25.11";

    # ── Shell ───────────────────────────────────────────────────────────
    programs.bash = {
      enable = true;
      shellAliases = {
        ll      = "ls -lah";
        gs      = "git status";
        rebuild = "sudo nixos-rebuild switch";
        update  = "sudo nixos-rebuild switch --upgrade";
      };
      # Run fastfetch on every new terminal session.
      initExtra = ''
        fastfetch
      '';
    };

    # ── Git ─────────────────────────────────────────────────────────────
    programs.git = {
      enable = true;
      settings.user = {
        name  = "Matthew";
        email = "matthew@kith.us";
      };
      settings.core = {
        editor   = "neovim";  # Use neovim for commit messages
        autocrlf = "input";   # Handle line endings correctly on Linux
      };
      settings.init = {
        defaultBranch = "main";
      };
      settings.pull = {
        rebase = false;       # Merge instead of rebase on pull
      };
    };

    # ── SSH ─────────────────────────────────────────────────────────────
    # Automatically add SSH keys to agent on first use — no manual
    # ssh-add needed after login.
    programs.ssh = {
      enable                = true;
      enableDefaultConfig   = false;
      matchBlocks."*" = {
        addKeysToAgent = "yes";
      };
    };

    # Start SSH agent automatically on login.
    services.ssh-agent.enable = true;

    # ── XDG Directories ─────────────────────────────────────────────────
    # Fixed: setSessionVariables = true silences the stateVersion warning
    xdg.userDirs = {
      enable              = true;
      createDirectories   = true;
      setSessionVariables = true;
      music               = "$HOME/Music";
      documents           = "$HOME/Documents";
      pictures            = "$HOME/Pictures";
      videos              = "$HOME/Videos";
      download            = "$HOME/Downloads";
    };
  };

  # ── Desktop Environment ───────────────────────────────────────────────
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # ── Steam ─────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # ── Gaming Tools ──────────────────────────────────────────────────────
  programs.gamemode.enable = true;   # CPU/GPU performance boost while gaming
  programs.gamescope.enable = true;  # Micro-compositor, helps with scaling

  # ── Audio ─────────────────────────────────────────────────────────────
  # Real-time audio priority — critical for low-latency recording
  # and preventing xruns in Reaper.
  security.rtkit.enable = true;

  # Allow audio group members to use real-time scheduling.
  security.pam.loginLimits = [
    { domain = "@audio"; type = "-"; item = "rtprio";  value = "99"; }
    { domain = "@audio"; type = "-"; item = "memlock"; value = "unlimited"; }
    { domain = "@audio"; type = "-"; item = "nice";    value = "-20"; }
  ];

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;  # Reaper works best via JACK
    # Note: MIDI is supported automatically via ALSA and JACK — no extra option needed

    extraConfig.pipewire = {
      "99-lowlatency" = {
        context.properties = {
          default.clock.rate        = 48000;
          default.clock.quantum     = 64;   # 64 is more stable than 32 for Reaper
          default.clock.min-quantum = 32;
          default.clock.max-quantum = 512;
        };
      };
    };
  };

  # ── Printing ──────────────────────────────────────────────────────────
  services.printing.enable = true;

  # ── Fonts ─────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    liberation_ttf
  ];

  # ── Firmware ──────────────────────────────────────────────────────────
  # Allows firmware updates via fwupdmgr.
  services.fwupd.enable = true;

  # ── LACT — AMD GPU Control ────────────────────────────────────────────
  # Allows overclocking, fan curves, power limits for RX 7800 XT.
  # Access via the LACT GUI app.
  services.lact.enable = true;

  # ── NextDNS ───────────────────────────────────────────────────────────
  services.nextdns = {
    enable = true;
    arguments = [
      "-config"     "de1313"  # Your NextDNS config ID
      "-cache-size" "10MB"
    ];
  };

  # Auto-activate NextDNS after each rebuild.
  systemd.services.nextdns-activate = {
    script = ''
      ${pkgs.nextdns}/bin/nextdns activate
    '';
    after    = [ "nextdns.service" ];
    wantedBy = [ "multi-user.target" ];
  };

  # ── Nix Flakes ────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Nix Store Maintenance ─────────────────────────────────────────────
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 30d";
  };
  nix.settings.auto-optimise-store = true;

  # ── State Version ─────────────────────────────────────────────────────
  # Do not change this after initial install.
  system.stateVersion = "25.11";

}
