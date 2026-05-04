# modules/nixos/services/fwupd.nix
#
# Firmware update daemon. Pulls firmware updates from the Linux
# Vendor Firmware Service (LVFS) for supported hardware: NVMe
# SSDs, motherboards, displays, docks, certain peripherals.
#
# Use:
#   fwupdmgr refresh         # pull latest metadata from LVFS
#   fwupdmgr get-devices     # list firmware-updatable devices
#   fwupdmgr get-updates     # check for updates
#   fwupdmgr update          # install available updates
#
# Skip on hosts that should be air-gapped or where firmware is
# managed out-of-band (some server hardware).

{ ... }:

{
  services.fwupd.enable = true;
}
