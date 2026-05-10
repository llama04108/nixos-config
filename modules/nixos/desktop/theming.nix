# modules/nixos/desktop/theming.nix
#
# System-wide theming via Stylix. One base16 color scheme drives
# GTK, Qt, cursor, fonts, ghostty, nvf colorscheme, fish, starship,
# Niri focus ring, SDDM login screen, and dozens of other targets.
#
# Theme experimentation: change `theme` in the let-block below and
# rebuild. Most surfaces update atomically. Surfaces NOT touched by
# Stylix that may need separate updates: Noctalia, Brave, Steam.
#
# Noctalia coexistence: set `syncGsettings: false` in Noctalia's
# settings (via its GUI) so Stylix owns gsettings/GTK rather than
# Noctalia. Noctalia continues to theme its own UI via its
# predefinedScheme setting.

{ pkgs, ... }:

let
  # Theme experimentation point. Swap this string and rebuild.
  # Available schemes: ${pkgs.base16-schemes}/share/themes/
  # A few worth trying:
  #   "catppuccin-mocha"   "catppuccin-frappe"   "catppuccin-macchiato"
  #   "tokyo-night-dark"   "rose-pine"           "rose-pine-moon"
  #   "gruvbox-dark-hard"  "nord"                "dracula"
  #   "kanagawa"           "everforest"          "oxocarbon-dark"
  theme = "catppuccin-mocha";
in

{
  stylix = {
    enable = true;
    polarity = "dark";

    base16Scheme = "${pkgs.base16-schemes}/share/themes/${theme}.yaml";

    # Wallpaper. Required by Stylix even with explicit base16Scheme —
    # SDDM's target uses it as login-screen background, the desktop
    # wallpaper handler uses it (when one is configured), and a few
    # other targets reference it.
    #
    # Placeholder solid color for now. Replace with a real wallpaper
    # path when one is chosen:
    #   image = ./wallpapers/your-wallpaper.png;
    image = pkgs.runCommand "placeholder-wallpaper.png" {} ''
      ${pkgs.imagemagick}/bin/magick -size 3840x2160 xc:'#1e1e2e' $out
    '';

    # ─── Cursor ───────────────────────────────────────────────────────
    cursor = {
      package = pkgs.catppuccin-cursors.mochaMauve;
      name = "catppuccin-mocha-mauve-cursors";
      size = 24;
    };

    # ─── Fonts ────────────────────────────────────────────────────────
    # Mirrors what we set system-wide in core/fonts.nix. Stylix uses
    # these to set per-app font config across themed targets.
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sizes = {
        applications = 11;
        terminal     = 12;
        desktop      = 11;
        popups       = 11;
      };
    };

    # ─── Target overrides ─────────────────────────────────────────────
    # autoEnable = true (default) means Stylix tries to theme any target
    # whose underlying app is detected. We disable specific targets
    # where we have deliberate independent choices.
    targets = {
      grub.enable     = false;   # not using GRUB (UEFI/systemd-boot)
      plymouth.enable = false;   # not enabled
    };

    # ─── Icon theme ───────────────────────────────────────────────────
    # Stylix doesn't pick an icon theme on its own; we provide one.
    # Papirus has explicit dark/light variants and follows the system
    # color scheme well.
    icons = {
      enable  = true;
      package = pkgs.papirus-icon-theme;
      dark    = "Papirus-Dark";
      light   = "Papirus-Light";
    };
  };
}
