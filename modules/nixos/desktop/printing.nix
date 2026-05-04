# modules/nixos/desktop/printing.nix
#
# CUPS printing + SANE scanning, driverless where possible.
#
# Tested target: Epson EcoTank ET-4850 (network MFP). The driverless
# stack (IPP Everywhere for print, eSCL/airscan for scan) supports
# this generation of EcoTank natively — no proprietary Epson drivers
# needed.
#
# Avahi enables mDNS so the printer is auto-discovered on the LAN
# without manual IP entry. nssmdns4 wires .local hostname resolution
# into NSS so apps can resolve the printer's mDNS name.
#
# Hosts that need printing import this module. Headless servers
# (gonk) skip it.

{ pkgs, ... }:

{
  # ─── Printing ───────────────────────────────────────────────────────
  services.printing = {
    enable = true;

    # Driverless first; epson-escpr2 as fallback for the few jobs
    # where IPP Everywhere quality isn't enough. Both being present
    # means CUPS can pick either when adding the printer.
    drivers = with pkgs; [
      epson-escpr2
    ];
  };

  # ─── mDNS / printer discovery ───────────────────────────────────────
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;  # allow mDNS through the firewall
  };

  # ─── Scanning ───────────────────────────────────────────────────────
  # SANE backend stack. sane-airscan handles network scanners that
  # speak eSCL (which the ET-4850 does). The user must be in the
  # `scanner` group to access scanners — added in the host file's
  # users.users.<name>.extraGroups.
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
    ];
  };

  # The generic scanner-discovery service. With sane-airscan and
  # avahi enabled, this should auto-find network scanners.
}
