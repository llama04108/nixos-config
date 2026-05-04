# hosts/sloane/default.nix
#
# Workstation host: gaming, music production (Bitwig, Reaper,
# LinnStrument, Kontakt-via-yabridge), 3D printing slicers, CAD,
# Blender. Intel i5-14600K + AMD RX 7800 XT.
#
# Encrypted btrfs root, separate ext4 SSD at /games.

{ config, pkgs, lib, inputs, ... }:

{
  # ─── Imports ────────────────────────────────────────────────────────
  # Pull in the hardware-detection file (generated at install time)
  # plus every module this host wants. As we build out more modules,
  # the list grows.
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core/boot/uefi.nix
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/core/locale.nix
  ];

  # ─── Identity ───────────────────────────────────────────────────────
  networking.hostName = "sloane";

  # ─── Module options (the audio module's knobs) ──────────────────────
  # Opt this host into the low-latency audio stack. The module's
  # defaults (48kHz, quantum=64) suit sloane, so we just enable it.
  local.audio.lowLatency.enable = true;

  # ─── User ───────────────────────────────────────────────────────────
  # Inline for now; will move to users/matthew/ with home-manager
  # integration once we've built a few more modules.
  #
  # `audio` group: PAM limits from the audio module apply.
  # `wheel`: sudo access.
  # `networkmanager`: edit network connections without root.
  users.users.matthew = {
    isNormalUser = true;
    description = "Matthew";
    extraGroups = [ "wheel" "networkmanager" "audio" ];
  };

  # ─── Nix settings ───────────────────────────────────────────────────
  # Required for any flake-based system. Will move to a
  # `core/nix-settings.nix` module soon.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ─── State version ──────────────────────────────────────────────────
  # Pin to the NixOS release this system was first installed on.
  # NEVER change this value after install — it's a marker for
  # NixOS to know which migration paths apply, not a "current
  # version" indicator. Updates happen via `nix flake update`.
  system.stateVersion = "25.11";
}
