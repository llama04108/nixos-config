# hosts/sloane/hardware-configuration.nix
#
# PLACEHOLDER — replaced at install time with the output of
# `nixos-generate-config` from the running NixOS installer.
#
# This stub exists so the flake evaluates from CachyOS during
# pre-install validation. The actual file will declare:
#   - boot.initrd kernel modules detected by the installer
#   - boot.kernelModules
#   - boot.initrd.luks.devices for the encrypted root
#   - fileSystems for /, /boot, /home, /nix, /games, etc.
#   - swapDevices
#   - hardware.cpu.intel.updateMicrocode
#   - networking.useDHCP defaults per-interface
#
# DO NOT EDIT after install — re-run nixos-generate-config and
# replace if hardware changes.

{ ... }:

{
  # The real file will populate these. Empty stubs just satisfy
  # the option types so the flake evaluates.
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/PLACEHOLDER";
    fsType = "ext4";
  };

  swapDevices = [ ];

  # Placeholder for the platform.
  nixpkgs.hostPlatform = "x86_64-linux";
}
