# modules/nixos/core/nix-settings.nix
#
# Nix daemon behavior: experimental features (flakes), automatic
# garbage collection, store optimization. Applies to every host —
# no reason to vary these per-machine for our use case.

{ ... }:

{
  nix = {
    # ─── Experimental features ──────────────────────────────────────
    # nix-command: enables modern `nix` CLI subcommands (build, run,
    # shell, flake, etc.) instead of just legacy nix-build, nix-shell.
    # flakes: enables flake support, which we obviously need.
    # Both are still gated behind the experimental flag despite being
    # the de facto standard since 2021. Likely to become default
    # eventually.
    settings.experimental-features = [ "nix-command" "flakes" ];

    # ─── Garbage collection ─────────────────────────────────────────
    # Nix never deletes old store paths automatically — every NixOS
    # generation keeps its full closure around for rollback. Without
    # GC, the store grows unboundedly. Weekly GC keeping 30 days of
    # history balances disk usage against rollback availability.
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 30d";
    };

    # ─── Store optimization ─────────────────────────────────────────
    # Hardlinks identical files in the store. Saves significant
    # disk space (often 20-40% on a busy store) at the cost of some
    # CPU during builds. Worth it on any machine with >100GB store.
    settings.auto-optimise-store = true;
  };
}
