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
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core/boot/uefi.nix
    ../../modules/nixos/core/locale.nix
    ../../modules/nixos/core/networking.nix
    ../../modules/nixos/core/nix-settings.nix
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/desktop/fonts.nix
    ../../modules/nixos/desktop/printing.nix
    ../../modules/nixos/hardware/amd-gpu.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/hardware/intel-cpu.nix
    ../../modules/nixos/services/flatpak.nix
    ../../modules/nixos/services/fwupd.nix
  ];

  # ─── Identity ───────────────────────────────────────────────────────
  networking.hostName = "sloane";

  # ─── Kernel ─────────────────────────────────────────────────────────
  # Latest stable kernel for current AMD GPU support, PipeWire fixes,
  # and Intel hybrid scheduler improvements. Sloane has modern hardware
  # and benefits from staying current. Older hosts (e.g., isard) will
  # likely use linuxPackages_lts instead — that's a per-host choice.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ─── Module options ─────────────────────────────────────────────────
  local.audio.lowLatency.enable        = true;
  local.networking.gamingTweaks.enable = true;
  local.hardware.amdGpu.rocm.enable    = true;

  # ─── User ───────────────────────────────────────────────────────────
  # Inline for now; will move to users/matthew/ with home-manager
  # integration once we've built a few more modules.
  users.users.matthew = {
    isNormalUser = true;
    description = "Matthew";
    extraGroups = [ "wheel" "networkmanager" "audio" "scanner" "lp" ];
  };

  # ─── State version ──────────────────────────────────────────────────
  # Pin to the NixOS release this system was first installed under.
  # NEVER change this value after install — it's a marker for NixOS
  # to know which migration paths apply, not a "current version"
  # indicator. Updates happen via `nix flake update`.
  system.stateVersion = "26.05";
}
