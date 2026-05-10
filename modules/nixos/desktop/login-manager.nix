# modules/nixos/desktop/login-manager.nix
#
# SDDM display manager with the Catppuccin Mocha Mauve theme.
# Wayland-native; uses the Qt6 SDDM package (required by the theme).
#
# The catppuccin-sddm package gets built with our chosen flavor and
# accent baked in, then installed system-wide so SDDM can locate the
# theme by name. The theme name "catppuccin-mocha-mauve" matches the
# directory the package creates under /usr/share/sddm/themes/.
#
# Hosts that have a graphical session import this module (directly
# or via a profile). Headless hosts (gonk, eventually) don't.
#
# Custom wallpaper background is deliberately not set here — the
# theme's bundled default background is fine for now; user wallpaper
# integration happens during the theming pass once we've decided
# what the wallpaper actually is.

{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;

    # Wayland greeter rather than X11. Required for compatibility with
    # the Niri session and consistent with the rest of our display
    # stack (no X11 anywhere by design).
    wayland.enable = true;

    # The catppuccin theme requires Qt6 SDDM. The default sddm package
    # is Qt5, which doesn't render the theme. kdePackages.sddm is the
    # Qt6 build.
    package = pkgs.kdePackages.sddm;

    theme = "catppuccin-mocha-mauve";
  };

  # Theme package. Built with mocha flavor and mauve accent to match
  # the system-wide Catppuccin theming.
  environment.systemPackages = [
    (pkgs.catppuccin-sddm.override {
      flavor = "mocha";
      accent = "mauve";
      font = "Noto Sans";
      fontSize = "9";
    })
  ];
}
