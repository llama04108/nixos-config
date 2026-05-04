# modules/nixos/core/networking.nix
#
# Base networking: NetworkManager for connection management, plus
# optional kernel-level tweaks for gaming and music-production
# workloads (lower latency, more aggressive memory behavior).
#
# Hostname is set in the host file, not here — it's intrinsically
# per-host.
#
# DNS server choice (NextDNS, etc.) lives in its own module and
# is responsible for setting networkmanager.dns appropriately.

{ config, lib, ... }:

let
  cfg = config.local.networking.gamingTweaks;
in
{
  # ─── Options ────────────────────────────────────────────────────────
  options.local.networking.gamingTweaks = {
    enable = lib.mkEnableOption ''
      kernel-level tweaks for gaming and low-latency audio:
      larger network backlog, TCP fast open, reduced swappiness,
      smaller dirty page ratios. Reasonable for any desktop workload;
      skip on headless servers where the defaults are tuned for
      throughput rather than latency.
    '';
  };

  # ─── Configuration ──────────────────────────────────────────────────
  config = {

    # NetworkManager: connection management daemon. Handles wifi,
    # ethernet, VPN, captive portals. Enabled on every host.
    networking.networkmanager.enable = true;

    # Gaming/low-latency kernel tweaks, opt-in.
    boot.kernel.sysctl = lib.mkIf cfg.enable {
      "net.core.netdev_max_backlog" = 16384;
      "net.ipv4.tcp_fastopen"       = 3;
      "vm.swappiness"               = 10;
      "vm.dirty_ratio"              = 6;
      "vm.dirty_background_ratio"   = 3;
    };
  };
}
