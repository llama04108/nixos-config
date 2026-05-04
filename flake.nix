{
  description = "Matthew's NixOS configurations — sloane and family";

  # ─── Inputs ──────────────────────────────────────────────────────────
  # Each input is an external dependency. Pinned by flake.lock once
  # this file is first evaluated. Updates happen via `nix flake update`.
  inputs = {

    # nixpkgs: the package set. unstable for current Niri/Noctalia/Bitwig
    # versions. flake.lock pins the exact commit.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # home-manager: NixOS module for declarative user configuration.
    # `follows` makes home-manager use OUR nixpkgs rather than its own
    # pinned version — avoids duplicate nixpkgs in the closure and
    # ensures pkgs.foo means the same thing in NixOS and home-manager
    # contexts.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri: scrollable-tiling Wayland compositor. We use the upstream
    # flake (rather than just pkgs.niri) for declarative config via
    # programs.niri.settings — write KDL config in Nix.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # noctalia: Quickshell-based desktop shell. Provides home-manager
    # module for declarative settings.json generation.
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-flatpak: declarative flatpak management. Used for Lychee
    # Slicer (closed-source, Flathub-only) and as a fallback for
    # Bambu Studio if the native package's cloud login fails.
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  # ─── Outputs ─────────────────────────────────────────────────────────
  # Outputs is a function. Nix calls it with the resolved inputs as
  # arguments. The `@inputs` part binds the entire arg set to the name
  # `inputs`, which we pass through to modules via specialArgs so
  # modules can reach Niri's and Noctalia's modules from inputs.<name>.
  outputs = { self, nixpkgs, home-manager, niri, noctalia, nix-flatpak, ... }@inputs:
  let
    # Shared system architecture. All five hosts are x86_64-linux.
    # If we ever add an ARM box, we'd lift this out per-host.
    system = "x86_64-linux";

    # Helper to reduce repetition when defining hosts. Each host gets
    # the same base modules (home-manager + nix-flatpak + niri's NixOS
    # module). Per-host modules go in the `extraModules` list.
    mkHost = hostname: extraModules:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${hostname}
          home-manager.nixosModules.home-manager
          nix-flatpak.nixosModules.nix-flatpak
          niri.nixosModules.niri
        ] ++ extraModules;
      };
  in {

    # Each entry = one machine. Hostname → NixOS configuration.
    # Built and activated via:
    #   sudo nixos-rebuild switch --flake .#<hostname>
    nixosConfigurations = {
      sloane = mkHost "sloane" [ ];

      # Future hosts — uncomment as we build each one out:
      # general-organa = mkHost "general-organa" [ ];
      # war-machine    = mkHost "war-machine"    [ ];
      # isard          = mkHost "isard"          [ ];
      # gonk           = mkHost "gonk"           [ ];
    };
  };
}
