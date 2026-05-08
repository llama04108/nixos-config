# hosts/sloane/default.nix
#
# Workstation host: gaming, music production (Bitwig, LinnStrument,
# Kontakt-via-yabridge), 3D printing slicers, CAD, Blender.
# Intel i5-14600K + AMD RX 7800 XT.
#
# Encrypted btrfs root, separate ext4 SSD at /games.

{ config, pkgs, lib, inputs, ... }:

{
  # ─── Imports ────────────────────────────────────────────────────────
  # Pulls in: hardware-configuration (auto-generated at install),
  # the UEFI bootloader module, and the workstation profile (which
  # in turn imports all the building-block modules sloane needs).
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core/boot/uefi.nix
    ../../modules/nixos/profiles/workstation.nix
    ../../modules/nixos/services/btrfs-maintenance.nix
    ../../modules/nixos/home-manager.nix
  ];

  # ─── Identity ───────────────────────────────────────────────────────
  networking.hostName = "sloane";

  # ─── Kernel ─────────────────────────────────────────────────────────
  # Latest stable kernel for current AMD GPU support, PipeWire fixes,
  # and Intel hybrid scheduler improvements. Older hosts (e.g., isard)
  # will use linuxPackages_lts instead.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ─── User ───────────────────────────────────────────────────────────
  # Inline for now; will move to users/matthew/ with home-manager
  # integration soon.
  #
  # Groups:
  #   wheel          — sudo
  #   networkmanager — edit network connections without root
  #   audio          — PAM rtprio/memlock limits from audio module
  #   scanner, lp    — scanner access and print job management
  users.users.matthew = {
    isNormalUser = true;
    description = "Matthew";
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" "audio" "scanner" "lp" ];
  };

  # ─── State version ──────────────────────────────────────────────────
  # Pin to the NixOS release this system was first installed under.
  # NEVER change this value after install — it's a marker for NixOS
  # to know which migration paths apply, not a "current version"
  # indicator. Updates happen via `nix flake update`.
  system.stateVersion = "26.05";
}
