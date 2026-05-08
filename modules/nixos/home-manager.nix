# modules/nixos/home-manager.nix
#
# Wires home-manager into NixOS. Hosts that have matthew as a
# user import this module, and home-manager's user config gets
# built and activated alongside the system config on rebuild.
#
# We use NixOS-module-mode home-manager (vs. standalone) so that
# `nixos-rebuild switch` rebuilds both system and user state in
# one atomic step. If the home-manager build fails, the whole
# system rebuild fails — a feature, not a bug.

{ inputs, ... }:

{
  home-manager = {
    # Use the system's nixpkgs (the one set up at flake level) for
    # home-manager too, rather than letting home-manager pull its
    # own. Means pkgs.foo is the same in both contexts.
    useGlobalPkgs   = true;
    useUserPackages = true;

    # Pass the flake inputs into home-manager modules so they can
    # reference inputs.nvf, inputs.noctalia, etc. Mirrors what
    # specialArgs does at the NixOS level.
    extraSpecialArgs = { inherit inputs; };

    # Per-user home-manager configuration. Each user is a separate
    # entry pointing at their config file.
    users.matthew = import ../../users/matthew;
  };
}
