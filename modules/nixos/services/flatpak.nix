# modules/nixos/services/flatpak.nix
#
# Declarative Flatpak management via nix-flatpak (a flake input).
# Used for apps that aren't in nixpkgs:
#
# - Lychee Slicer (resin printing, closed source, Flathub-only)
#
# Bambu Studio is in nixpkgs, but if its cloud login keeps failing
# the Flatpak version (com.bambulab.BambuStudio) is a known-working
# fallback. Add it here if needed.
#
# Flatpaks update on Flathub's schedule, so true reproducibility
# isn't possible — we accept this and let nix-flatpak's auto-update
# keep things current weekly.

{ ... }:

{
  services.flatpak = {
    # Whether to install/uninstall Flatpaks to match this list.
    # Apps installed manually with `flatpak install` outside this
    # config will be removed on rebuild. Set to false if you want
    # to mix declarative and imperative Flatpak management.
    uninstallUnmanaged = true;

    # The Flatpak applications to install. Use the full reverse-DNS
    # app ID from Flathub.
    packages = [
      "io.mango3d.LycheeSlicer"
    ];

    # Auto-update weekly via systemd timer. The persistent timer
    # catches up after machine downtime.
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}
