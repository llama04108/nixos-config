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
    RADV_PERFTEST  = "gpl";
    DXVK_ASYNC     = "1";
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
  services.xserver.xkb.layout = "us";

  # Disable mouse acceleration — flat profile gives 1:1 movement.
  services.libinput.mouse.accelProfile = "flat";

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
    dualsensectl        # PS5 DualSense controller — lightbar, LEDs, battery, mic control

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

  home-manager.users.matthew = { pkgs, cosmicLib, ... }: {
    imports = [ <cosmic-manager/modules> ];

    home.stateVersion = "25.11";

    # ── Shell ───────────────────────────────────────────────────────────
    programs.bash = {
      enable = true;
      shellAliases = {
        ll      = "ls -lah";
        gs      = "git status";
        rebuild = "sudo nixos-rebuild switch";
        update  = "sudo nixos-rebuild switch --upgrade";
        apply   = "~/update-config.sh";
        gitsync = ''read -p "Commit message: " msg && git -C /etc/nixos add -A && git -C /etc/nixos commit -m "$msg" && git -C /etc/nixos push'';
      };
      initExtra = ''
        fastfetch
      '';
    };

    # ── Starship prompt ─────────────────────────────────────────────────
    # Single-line prompt using Catppuccin Mocha colors.
    programs.starship = {
      enable = true;
      settings = {
        palette = "catppuccin_mocha";
        palettes.catppuccin_mocha = {
          rosewater = "#f5e0dc";
          flamingo  = "#f2cdcd";
          pink      = "#f5c2e7";
          mauve     = "#cba6f7";
          red       = "#f38ba8";
          maroon    = "#eba0ac";
          peach     = "#fab387";
          yellow    = "#f9e2af";
          green     = "#a6e3a1";
          teal      = "#94e2d5";
          sky       = "#89dceb";
          sapphire  = "#74c7ec";
          blue      = "#89b4fa";
          lavender  = "#b4befe";
          text      = "#cdd6f4";
          subtext1  = "#bac2de";
          subtext0  = "#a6adc8";
          overlay2  = "#9399b2";
          overlay1  = "#7f849c";
          overlay0  = "#6c7086";
          surface2  = "#585b70";
          surface1  = "#45475a";
          surface0  = "#313244";
          base      = "#1e1e2e";
          mantle    = "#181825";
          crust     = "#11111b";
        };

        format = "$username$hostname$directory$character";

        username = {
          style_user  = "bold blue";
          style_root  = "bold red";
          format      = "[$user]($style)";
          show_always = true;
        };

        hostname = {
          style    = "bold mauve";
          format   = "[@$hostname]($style) ";
          ssh_only = false;
        };

        directory = {
          style             = "bold lavender";
          format            = "[$path]($style) ";
          truncation_length = 3;
          truncate_to_repo  = false;
        };

        character = {
          success_symbol = "[❯](bold green)";
          error_symbol   = "[❯](bold red)";
        };

        python.disabled   = true;
        nodejs.disabled   = true;
        rust.disabled     = true;
        package.disabled  = true;
        nix_shell.disabled = true;
      };
    };

    # ── Git ─────────────────────────────────────────────────────────────
    programs.git = {
      enable = true;
      settings.user = {
        name  = "TK4108";
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

    # ── Neovim ──────────────────────────────────────────────────────────
    programs.neovim = {
      enable        = true;
      defaultEditor = true;   # makes neovim the default $EDITOR system-wide
      viAlias       = true;   # lets you type 'vi' to open neovim
      vimAlias      = true;   # lets you type 'vim' to open neovim

      plugins = with pkgs.vimPlugins; [
        # Theme
        catppuccin-nvim

        # File tree sidebar — browse your files
        nvim-tree-lua
        nvim-web-devicons

        # Fuzzy finder — quickly open any file by typing part of its name
        telescope-nvim
        plenary-nvim

        # Status bar showing file, mode, and git info
        lualine-nvim

        # LSP — shows errors and gives autocomplete for Nix and Bash
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        luasnip

        # Shows available keybindings when you press Space
        which-key-nvim

        # Auto-close brackets and quotes
        nvim-autopairs

        # Comment lines with gcc
        comment-nvim
      ];

      # Language servers for Nix and Bash
      extraPackages = with pkgs; [
        nil                   # Nix LSP
        bash-language-server  # Bash LSP
      ];

      initLua = ''
        -- ── General settings ────────────────────────────────────────────
        vim.opt.number        = true
        vim.opt.expandtab     = true
        vim.opt.tabstop       = 2
        vim.opt.shiftwidth    = 2
        vim.opt.smartindent   = true
        vim.opt.scrolloff     = 5
        vim.opt.termguicolors = true
        vim.opt.clipboard     = "unnamedplus"
        vim.opt.mouse         = "a"
        vim.opt.ignorecase    = true
        vim.opt.smartcase     = true
        vim.opt.wrap          = true
        vim.opt.linebreak     = true

        -- ── Theme ────────────────────────────────────────────────────────
        require("catppuccin").setup({ flavour = "mocha" })
        vim.cmd.colorscheme("catppuccin-mocha")

        -- ── File tree ────────────────────────────────────────────────────
        require("nvim-tree").setup()
        vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>",
          { silent = true, desc = "Toggle file tree" })

        -- ── Telescope ────────────────────────────────────────────────────
        local telescope = require("telescope.builtin")
        vim.keymap.set("n", "<leader>ff", telescope.find_files,  { desc = "Find files" })
        vim.keymap.set("n", "<leader>fg", telescope.live_grep,   { desc = "Search in files" })
        vim.keymap.set("n", "<leader>fb", telescope.buffers,     { desc = "Open buffers" })

        -- ── Status bar ───────────────────────────────────────────────────
        require("lualine").setup({
          options = {
            theme        = "catppuccin",
            globalstatus = true,
          },
          sections = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff" },
            lualine_c = { "filename" },
            lualine_x = { "diagnostics", "filetype" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
          },
        })

        -- ── Which-key ────────────────────────────────────────────────────
        require("which-key").setup()

        -- ── LSP ──────────────────────────────────────────────────────────
        -- Neovim 0.11+ built-in LSP config (replaces nvim-lspconfig)
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        vim.lsp.config("nil_ls", {
          cmd          = { "nil" },
          filetypes    = { "nix" },
          root_markers = { "flake.nix", ".git" },
          capabilities = capabilities,
        })
        vim.lsp.enable("nil_ls")

        vim.lsp.config("bash_ls", {
          cmd          = { "bash-language-server", "start" },
          filetypes    = { "bash", "sh" },
          capabilities = capabilities,
        })
        vim.lsp.enable("bash_ls")

        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(ev)
            local opts = { buffer = ev.buf }
            vim.keymap.set("n", "K",  vim.lsp.buf.hover,      opts)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          end,
        })

        -- ── Autocompletion ───────────────────────────────────────────────
        local cmp     = require("cmp")
        local luasnip = require("luasnip")
        cmp.setup({
          snippet = {
            expand = function(args) luasnip.lsp_expand(args.body) end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<Tab>"]     = cmp.mapping.select_next_item(),
            ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
            ["<CR>"]      = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
          }),
          sources = {
            { name = "nvim_lsp" },
            { name = "buffer" },
            { name = "path" },
          },
        })

        -- ── Auto pairs ───────────────────────────────────────────────────
        require("nvim-autopairs").setup()

        -- ── Comments ─────────────────────────────────────────────────────
        require("Comment").setup()
      '';
    };

    # ── GTK Theme ────────────────────────────────────────────────────────
    # Catppuccin Mocha for LibreWolf, GIMP, LibreOffice and other GTK apps.
    gtk = {
      enable = true;
      theme = {
        name    = "Catppuccin-Mocha-Standard-Mauve-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "mauve" ];
          variant = "mocha";
        };
      };
      iconTheme = {
        name    = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      font = {
        name = "Noto Sans";
        size = 11;
      };
      gtk4.theme = null;
    };

    # ── Nano ─────────────────────────────────────────────────────────────
    # Catppuccin Mocha color scheme for nano.
    home.file.".nanorc".text = ''
      set linenumbers
      set autoindent
      set tabsize 2
      set tabstospaces
      set mouse
      set softwrap

      ## Catppuccin Mocha colors
      set titlecolor bold,white,#1e1e2e
      set statuscolor bold,white,#1e1e2e
      set errorcolor bold,white,#f38ba8
      set selectedcolor bold,black,#89b4fa
      set stripecolor ,#313244
      set scrollercolor ,#45475a
      set numbercolor cyan,#1e1e2e
      set keycolor bold,cyan,#1e1e2e
      set functioncolor green,#1e1e2e
    '';

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

    # Hide Neovim wrapper desktop entry — removes duplicate from launcher.
    xdg.desktopEntries.nvim = {
      name      = "Neovim";
      noDisplay = true;
    };

    # ── COSMIC Manager ──────────────────────────────────────────────────
    # Declarative COSMIC desktop configuration via cosmic-manager.
    # Requires: sudo nix-channel --add \
    #   https://github.com/HeitorAugustoLN/cosmic-manager/archive/main.tar.gz \
    #   cosmic-manager && sudo nix-channel --update
    wayland.desktopManager.cosmic.enable = true;

    # ── COSMIC Appearance ───────────────────────────────────────────────
    wayland.desktopManager.cosmic.appearance.theme.dark = {
      active_hint = 1;  # 1px window border
      gaps = cosmicLib.cosmic.mkRON "tuple" [ 3 3 ];  # 3px gaps around tiled windows
      # Catppuccin Mocha mauve (#cba6f7) — closest to Proton Carbon's purple accent
      accent = cosmicLib.cosmic.mkRON "optional" {
        red   = 0.796;
        green = 0.651;
        blue  = 0.969;
      };
      corner_radii = {
        radius_0  = cosmicLib.cosmic.mkRON "tuple" [ 0.0  0.0  0.0  0.0  ];
        radius_xs = cosmicLib.cosmic.mkRON "tuple" [ 2.0  2.0  2.0  2.0  ];
        radius_s  = cosmicLib.cosmic.mkRON "tuple" [ 4.0  4.0  4.0  4.0  ];
        radius_m  = cosmicLib.cosmic.mkRON "tuple" [ 8.0  8.0  8.0  8.0  ];
        radius_l  = cosmicLib.cosmic.mkRON "tuple" [ 16.0 16.0 16.0 16.0 ];
        radius_xl = cosmicLib.cosmic.mkRON "tuple" [ 32.0 32.0 32.0 32.0 ];
      };
    };

    # ── COSMIC Terminal ─────────────────────────────────────────────────
    programs.cosmic-term = {
      enable  = true;
      package = null;  # already installed by services.desktopManager.cosmic
      settings = {
        app_theme        = cosmicLib.cosmic.mkRON "enum" "Dark";
        font_name        = "JetBrains Mono";
        font_size        = 14;
        opacity          = 100;
        show_headerbar   = true;
        use_bright_bold  = true;
      };
      # Catppuccin Mocha — matches Neovim and Proton Carbon theme
      colorSchemes = [
        {
          name              = "Catppuccin Mocha";
          mode              = "dark";
          foreground        = "#cdd6f4";
          bright_foreground = "#cdd6f4";
          dim_foreground    = "#a6adc8";
          cursor            = "#f5e0dc";
          normal = {
            black   = "#45475a";
            red     = "#f38ba8";
            green   = "#a6e3a1";
            yellow  = "#f9e2af";
            blue    = "#89b4fa";
            magenta = "#f5c2e7";
            cyan    = "#94e2d5";
            white   = "#bac2de";
          };
          bright = {
            black   = "#585b70";
            red     = "#f38ba8";
            green   = "#a6e3a1";
            yellow  = "#f9e2af";
            blue    = "#89b4fa";
            magenta = "#f5c2e7";
            cyan    = "#94e2d5";
            white   = "#a6adc8";
          };
          dim = {
            black   = "#45475a";
            red     = "#f38ba8";
            green   = "#a6e3a1";
            yellow  = "#f9e2af";
            blue    = "#89b4fa";
            magenta = "#f5c2e7";
            cyan    = "#94e2d5";
            white   = "#bac2de";
          };
        }
      ];
      profiles = [
        {
          name               = "Default";
          is_default         = true;
          hold               = false;
          command            = "bash";
          syntax_theme_dark  = "Catppuccin Mocha";
          syntax_theme_light = "COSMIC Light";
        }
      ];
    };

    # ── COSMIC Files ────────────────────────────────────────────────────
    programs.cosmic-files = {
      enable  = true;
      package = null;  # already installed by services.desktopManager.cosmic
      settings = {
        app_theme    = cosmicLib.cosmic.mkRON "enum" "Dark";
        show_details = false;
        desktop = {
          show_content        = true;
          show_mounted_drives = true;
          show_trash          = false;
        };
        tab = {
          folders_first = true;
          show_hidden   = false;
          view          = cosmicLib.cosmic.mkRON "enum" "List";
          icon_sizes = {
            grid = 100;
            list = 100;
          };
        };
        favorites = [
          (cosmicLib.cosmic.mkRON "enum" "Home")
          (cosmicLib.cosmic.mkRON "enum" "Documents")
          (cosmicLib.cosmic.mkRON "enum" "Downloads")
          (cosmicLib.cosmic.mkRON "enum" "Music")
          (cosmicLib.cosmic.mkRON "enum" "Pictures")
          (cosmicLib.cosmic.mkRON "enum" "Videos")
          (cosmicLib.cosmic.mkRON "enum" { value = [ "/games" ]; variant = "Path"; })
        ];
      };
    };

    # ── COSMIC Text Editor ───────────────────────────────────────────────
    programs.cosmic-edit = {
      enable  = true;
      package = null;  # already installed by services.desktopManager.cosmic
      settings = {
        app_theme           = cosmicLib.cosmic.mkRON "enum" "Dark";
        font_name           = "JetBrains Mono";
        font_size           = 14;
        tab_width           = 2;
        auto_indent         = true;
        word_wrap           = true;
        line_numbers        = true;
        highlight_current_line = true;
        vim_bindings        = true;   # vim keybindings enabled
        syntax_theme_dark   = "Dracula";
        syntax_theme_light  = "COSMIC Light";
      };
    };

    # ── COSMIC App Library ───────────────────────────────────────────────
    # Note: App Library groups are best configured through the UI since
    # app IDs vary by installation method and the RON tuple enum format
    # for filters is not reliably expressible via cosmic-manager.
    programs.cosmic-applibrary.enable = true;

    # ── COSMIC Store ─────────────────────────────────────────────────────
    programs.cosmic-store = {
      enable = true;
      settings = {
        app_theme = cosmicLib.cosmic.mkRON "enum" "Dark";
      };
    };

    # ── COSMIC Media Player ──────────────────────────────────────────────
    programs.cosmic-player = {
      enable  = true;
      package = null;  # already installed by services.desktopManager.cosmic
      settings = {
        app_theme = cosmicLib.cosmic.mkRON "enum" "Dark";
      };
    };

    # ── Forecast (Weather) ───────────────────────────────────────────────
    programs.forecast = {
      enable = true;
      settings = {
        app_theme      = cosmicLib.cosmic.mkRON "enum" "Dark";
        timefmt        = cosmicLib.cosmic.mkRON "enum" "TwentyFourHr";
        units          = cosmicLib.cosmic.mkRON "enum" "Fahrenheit";
        speed_units    = cosmicLib.cosmic.mkRON "enum" "MilesPerHour";
        pressure_units = cosmicLib.cosmic.mkRON "enum" "Hectopascal";
        default_page   = cosmicLib.cosmic.mkRON "enum" "HourlyView";
        # Finksburg, MD
        location  = cosmicLib.cosmic.mkRON "optional" "Finksburg, MD";
        latitude  = cosmicLib.cosmic.mkRON "optional" "39.4912";
        longitude = cosmicLib.cosmic.mkRON "optional" "-76.8747";
      };
    };

    # ── COSMIC Tasks ─────────────────────────────────────────────────────
    programs.tasks = {
      enable = true;
      settings = {
        app_theme = cosmicLib.cosmic.mkRON "enum" "Dark";
      };
    };

    # ── COSMIC Tweaks ────────────────────────────────────────────────────
    programs.cosmic-ext-tweaks = {
      enable = true;
      settings = {
        app_theme = cosmicLib.cosmic.mkRON "enum" "Dark";
      };
    };
  };

  # ── Desktop Environment ───────────────────────────────────────────────
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # ── Chromium ──────────────────────────────────────────────────────────
  programs.chromium = {
    enable = true;
    extensions = [
      "bkkmolkhemgaeaeggcmcofaljaljmgdn"  # Catppuccin Mocha theme
    ];
  };

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
    jetbrains-mono       # Used in COSMIC Terminal, Text Editor, and Neovim
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
