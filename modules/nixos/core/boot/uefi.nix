# modules/nixos/core/boot/uefi.nix
#
# UEFI bootloader using systemd-boot. Simple, fast, no GRUB
# complexity. Works with LUKS-encrypted root because /boot lives
# on a separate unencrypted EFI System Partition (FAT32).
#
# Hosts opt in by importing this file directly. There is no
# enable option — if you import this module, you want UEFI boot.
# Hosts that want BIOS/GRUB instead import core/boot/bios.nix.

{ ... }:

{
  boot.loader = {
    # systemd-boot: NixOS's default UEFI bootloader. Each NixOS
    # generation gets a menu entry. Boots in ~1 second on modern
    # hardware. No legacy BIOS support.
    systemd-boot.enable = true;

    # Allow systemd-boot to write to NVRAM (where UEFI boot
    # entries live). Without this, you'd have to manually run
    # bootctl after every NixOS generation. Set to false on
    # systems where you want NVRAM frozen (rare).
    efi.canTouchEfiVariables = true;
  };
}
