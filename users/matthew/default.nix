# users/matthew/default.nix
#
# matthew's home-manager configuration. Imported by every host
# that has matthew as a user. Currently a stub — actual content
# comes in subsequent commits.
#
# This file defines configuration for the matthew user account
# at the home-manager level (dotfiles, user packages, programs).
# System-level user setup (groups, shell, password) lives in the
# host file's users.users.matthew block.

{ ... }:

{
  # ─── home-manager state version ─────────────────────────────────────
  # Same purpose as system.stateVersion: NixOS uses this to decide
  # which migration paths apply for home-manager's own evolving
  # options. Pin to whatever NixOS release we initially set up under.
  # NEVER change after first install.
  home.stateVersion = "26.05";

  # ─── home-manager self-management ───────────────────────────────────
  # Tell home-manager to install itself as a user package. Without
  # this, you couldn't run `home-manager` as a command for ad-hoc
  # operations. Standard pattern, always wanted.
  programs.home-manager.enable = true;
}
