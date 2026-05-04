# modules/nixos/hardware/bluetooth.nix
#
# Bluetooth stack via BlueZ. Powers on at boot so paired devices
# (audio, MIDI controllers, peripherals) are available immediately.
#
# Hosts that don't need bluetooth (headless servers, minimal kid
# desktops) just don't import this module.

{ ... }:

{
  hardware.bluetooth = {
    enable = true;

    # Power on the radio at boot. Without this, the radio is
    # available but off — you'd have to `bluetoothctl power on`
    # after every reboot. For desktop use, on-by-default is right.
    # On a laptop where you'd prefer bluetooth off until needed
    # (battery), set this to false in the host file.
    powerOnBoot = true;
  };
}
