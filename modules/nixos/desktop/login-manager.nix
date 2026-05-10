# modules/nixos/desktop/login-manager.nix
#
# SDDM display manager. Theme is provided by Stylix's targets.sddm,
# which generates a minimal themed login screen from the system
# base16 color scheme and uses stylix.image as the background.
#
# Hosts that have a graphical session import this module (directly
# or via a profile). Headless hosts (gonk, eventually) don't.

{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;

    # Qt6 SDDM. Required for current Stylix sddm target compatibility.
    # The Qt5 default sddm package may not render Stylix's generated
    # theme correctly.
    package = pkgs.kdePackages.sddm;
  };
}
