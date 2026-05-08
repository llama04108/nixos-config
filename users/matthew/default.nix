# users/matthew/default.nix
#
# matthew's home-manager configuration. Imported by every host
# that has matthew as a user.
#
# This file defines configuration for the matthew user account
# at the home-manager level (dotfiles, user packages, programs).
# System-level user setup (groups, shell, password) lives in the
# host file's users.users.matthew block.

{ pkgs, ... }:

{
  # ─── Identity ───────────────────────────────────────────────────────
  # home-manager needs to know the username and home directory
  # explicitly when used as a NixOS module. Without these, it can't
  # decide where to write user-level files.
  home.username      = "matthew";
  home.homeDirectory = "/home/matthew";

  # ─── State version ──────────────────────────────────────────────────
  # Same purpose as system.stateVersion: marks which migration paths
  # apply for home-manager's own evolving options. NEVER change.
  home.stateVersion = "26.05";

  # ─── home-manager self-management ───────────────────────────────────
  # Lets `home-manager` work as a user-level command for ad-hoc ops.
  programs.home-manager.enable = true;

  # ─── XDG directories ────────────────────────────────────────────────
  # Standard XDG Base Directory layout. Many apps respect these env
  # vars and write their config/data under them rather than dropping
  # dotfiles in $HOME.
  xdg.enable = true;

  # ─── User packages ──────────────────────────────────────────────────
  # User-level packages live here. System-level packages stay in the
  # workstation profile. Generally speaking: anything that's a personal
  # tool (editor, CLI util, fonts you've collected) goes user-level;
  # anything that needs system integration (steam, drivers, services)
  # stays system-level.
  home.packages = with pkgs; [
    # nothing here yet — will fill in as needed
  ];

  # ─── Fish ───────────────────────────────────────────────────────────
  # User-level fish config. System-level (programs.fish.enable) lives
  # in the workstation profile. Here we set abbreviations, plugins,
  # and any user-specific shell config.
  programs.fish = {
    enable = true;

    # Abbreviations expand as you type (you type `gst <space>` and it
    # becomes `git status`). Better than aliases for muscle memory —
    # you see exactly what's running.
    shellAbbrs = {
      # git
      gs   = "git status";
      gd   = "git diff";
      gds  = "git diff --staged";
      ga   = "git add";
      gaa  = "git add -A";
      gc   = "git commit";
      gcm  = "git commit -m";
      gca  = "git commit --amend";
      gp   = "git push";
      gpl  = "git pull";
      gl   = "git log --oneline -20";
      gco  = "git checkout";
      gb   = "git branch";

      # nix
      nfu  = "nix flake update";
      nfc  = "nix flake check";
      nrs  = "sudo nixos-rebuild switch --flake .";
      nrt  = "sudo nixos-rebuild test --flake .";
      nrb  = "sudo nixos-rebuild build --flake .";

      # general
      ll   = "ls -lah";
      ".." = "cd ..";
    };

    # Functions and one-off init can go here as needed. Empty for now.
    interactiveShellInit = ''
      # Disable the default fish greeting (the colorful welcome message).
      # Cleaner on every new terminal — fastfetch covers the "what's
      # this machine" greeting already.
      set -g fish_greeting
    '';
  };

  # ─── Starship prompt ────────────────────────────────────────────────
  # Cross-shell prompt with sensible defaults. Configures itself for
  # fish automatically since fish is enabled above. The default theme
  # is fine; we'll customize during the theming pass if needed.
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  # ─── direnv ─────────────────────────────────────────────────────────
  # Auto-loads environment variables from .envrc files when entering
  # a directory. Combined with nix-direnv, automatically loads flake
  # devshells when you `cd` into a project — no `nix develop` needed.
  #
  # Usage in a project: create `.envrc` with `use flake`, then run
  # `direnv allow`. Each cd in/out of the project dir loads/unloads
  # the devshell automatically.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  # ─── Git ────────────────────────────────────────────────────────────
  # User-level git config. Identity, default branch, SSH commit
  # signing, and a few sensible defaults.
  programs.git = {
    enable = true;

    # SSH commit signing. Uses the SSH key at ~/.ssh/id_ed25519.pub
    # rather than GPG. Same end result on GitHub (Verified badge),
    # much simpler than GPG keyring management.
    #
    # The key file referenced here is created post-install via
    # `ssh-keygen` — see POST_INSTALL.md (forthcoming).
    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
      format = "ssh";
    };

    # Modern unified config tree. Mirrors git's actual config layout
    # (e.g., `git config user.name` → settings.user.name).
    settings = {
      user = {
        name  = "llama04108";
        email = "matthew@kith.us";
      };
      init.defaultBranch   = "main";
      pull.rebase          = true;        # rebase on pull, don't merge
      push.autoSetupRemote = true;        # set upstream automatically
      core.editor          = "nvim";      # nvf provides this binary
      diff.colorMoved      = "default";   # nicer move detection in diffs
    };
  };
}
