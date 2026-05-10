# modules/nixos/services/openssh.nix
#
# OpenSSH daemon. Enabled on every host — it's the recovery net
# when something goes wrong with the graphical session. Even
# sloane (a workstation, not a server) benefits from being SSH-able
# from another machine on the LAN.
#
# Default config: password auth ENABLED for initial install
# (so we can ssh in before key-based auth is configured),
# root login DISABLED. After first login and key setup, switch
# PasswordAuthentication to false.

{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      # Initial install needs password auth — we can't put SSH keys
      # on the machine before we can log in to put them there.
      # Switch to false after key-based auth is set up.
      PasswordAuthentication = true;

      # Never permit direct root login over SSH. Use sudo from
      # a normal account instead.
      PermitRootLogin = "no";
    };
  };

  # Open the SSH port. Default is 22 — change here if we ever
  # want to run on a non-standard port (we don't, for now).
  networking.firewall.allowedTCPPorts = [ 22 ];
}
