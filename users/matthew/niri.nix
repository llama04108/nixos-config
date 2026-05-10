# users/matthew/niri.nix
#
# Niri compositor configuration. Ported from the working
# ~/.config/niri/config.kdl on CachyOS, with deliberate updates:
#   - Mod+T spawns ghostty (was alacritty)
#   - Print/Ctrl+Print/Alt+Print bindings removed (no Print key)
#   - Mod+Shift+S annotation pipeline added (grim+slurp+satty)
#   - Catppuccin Mocha Mauve focus-ring colors
#
# Output configuration is intentionally not set — Niri auto-detects
# the HDMI-A-6 LG TV at 3840x2160@60 with scale 1, which is what
# we want. Override here only if a future hardware change demands it.
#
# Reference: https://yalter.github.io/niri/Configuration:-Introduction

{ config, pkgs, ... }:

{
  programs.niri.settings = {

    # ─── Input ────────────────────────────────────────────────────────
    input = {
      keyboard = {
        # Empty xkb block: niri pulls layout from org.freedesktop.locale1
        # (set via system-level localectl). en_US already configured
        # via core/locale.nix at the system level.
        xkb = { };
        numlock = true;
      };

      touchpad = {
        tap = true;
        natural-scroll = true;
      };

      # Mouse / trackpoint defaults are fine.
    };

    # ─── Layout ───────────────────────────────────────────────────────
    layout = {
      gaps = 16;
      center-focused-column = "never";

      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.50000; }
        { proportion = 0.66667; }
      ];
      default-column-width.proportion = 0.50000;

      # Focus ring colors are set by Stylix via niri-flake's target.
      # We just enable the ring; colors come from the theme.
      focus-ring = {
        enable = true;
        width = 4;
      };

      # Border off; just the focus ring for cleaner look.
      border = {
        enable = false;
        width = 4;
      };

      shadow = {
        enable = false;
        softness = 30;
        spread = 5;
        offset = { x = 0; y = 5; };
        color = "#0007";
      };

      struts = { };
    };

    # ─── Spawn at startup ─────────────────────────────────────────────
    # Noctalia as shell. `qs` is Quickshell's CLI; `-c noctalia-shell`
    # tells it to load the Noctalia configuration.
    spawn-at-startup = [
      { command = [ "qs" "-c" "noctalia-shell" ]; }
    ];

    # ─── Hotkey overlay ───────────────────────────────────────────────
    hotkey-overlay.skip-at-startup = false;

    # ─── Screenshot path ──────────────────────────────────────────────
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    # ─── Animations ───────────────────────────────────────────────────
    animations.enable = true;

    # ─── Window rules ─────────────────────────────────────────────────
    window-rules = [
      # Work around WezTerm's initial configure bug.
      {
        matches = [{ app-id = "^org\\.wezfurlong\\.wezterm$"; }];
        default-column-width = { };
      }

      # Firefox / LibreWolf picture-in-picture floats.
      {
        matches = [{
          app-id = "firefox$";
          title = "^Picture-in-Picture$";
        }];
        open-floating = true;
      }
    ];

    # ─── Binds ────────────────────────────────────────────────────────
    binds = with config.lib.niri.actions; let
      sh = spawn "sh" "-c";
    in {
      # ─ Hotkey overlay ─
      "Mod+Shift+Slash".action = show-hotkey-overlay;

      # ─ Programs ─
      "Mod+T" = {
        action = spawn "ghostty";
        hotkey-overlay.title = "Open a Terminal: ghostty";
      };
      "Mod+D" = {
        action = sh "qs -c noctalia-shell ipc call launcher toggle";
        hotkey-overlay.title = "Run an Application Launcher";
      };
      "Super+Alt+L" = {
        action = sh "qs -c noctalia-shell ipc call lockScreen toggle";
        hotkey-overlay.title = "Lock the Screen";
      };
      "Mod+B".action = spawn "librewolf";

      # Screen reader toggle (orca). No hotkey-overlay title — this
      # binding is intentionally hidden from the help screen.
      "Super+Alt+S" = {
        action = sh "pkill orca || exec orca";
        allow-when-locked = true;
      };

      # ─ Volume / mute ─
      "XF86AudioRaiseVolume" = {
        action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action = sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        allow-when-locked = true;
      };

      # ─ Media keys ─
      "XF86AudioPlay" = { action = sh "playerctl play-pause"; allow-when-locked = true; };
      "XF86AudioStop" = { action = sh "playerctl stop";       allow-when-locked = true; };
      "XF86AudioPrev" = { action = sh "playerctl previous";   allow-when-locked = true; };
      "XF86AudioNext" = { action = sh "playerctl next";       allow-when-locked = true; };

      # ─ Brightness ─
      "XF86MonBrightnessUp" = {
        action = spawn "brightnessctl" "--class=backlight" "set" "+10%";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action = spawn "brightnessctl" "--class=backlight" "set" "10%-";
        allow-when-locked = true;
      };

      # ─ Overview ─
      "Mod+O" = {
        action = toggle-overview;
        repeat = false;
      };

      # ─ Window close ─
      "Mod+Q" = {
        action = close-window;
        repeat = false;
      };

      # ─ Focus / movement ─
      "Mod+Left".action  = focus-column-left;
      "Mod+Down".action  = focus-window-down;
      "Mod+Up".action    = focus-window-up;
      "Mod+Right".action = focus-column-right;
      "Mod+H".action     = focus-column-left;
      "Mod+J".action     = focus-window-down;
      "Mod+K".action     = focus-window-up;
      "Mod+L".action     = focus-column-right;

      "Mod+Ctrl+Left".action  = move-column-left;
      "Mod+Ctrl+Down".action  = move-window-down;
      "Mod+Ctrl+Up".action    = move-window-up;
      "Mod+Ctrl+Right".action = move-column-right;
      "Mod+Ctrl+H".action     = move-column-left;
      "Mod+Ctrl+J".action     = move-window-down;
      "Mod+Ctrl+K".action     = move-window-up;
      "Mod+Ctrl+L".action     = move-column-right;

      "Mod+Home".action      = focus-column-first;
      "Mod+End".action       = focus-column-last;
      "Mod+Ctrl+Home".action = move-column-to-first;
      "Mod+Ctrl+End".action  = move-column-to-last;

      # ─ Monitor focus / movement ─
      "Mod+Shift+Left".action  = focus-monitor-left;
      "Mod+Shift+Down".action  = focus-monitor-down;
      "Mod+Shift+Up".action    = focus-monitor-up;
      "Mod+Shift+Right".action = focus-monitor-right;
      "Mod+Shift+H".action     = focus-monitor-left;
      "Mod+Shift+J".action     = focus-monitor-down;
      "Mod+Shift+K".action     = focus-monitor-up;
      "Mod+Shift+L".action     = focus-monitor-right;

      "Mod+Shift+Ctrl+Left".action  = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+Down".action  = move-column-to-monitor-down;
      "Mod+Shift+Ctrl+Up".action    = move-column-to-monitor-up;
      "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
      "Mod+Shift+Ctrl+H".action     = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+J".action     = move-column-to-monitor-down;
      "Mod+Shift+Ctrl+K".action     = move-column-to-monitor-up;
      "Mod+Shift+Ctrl+L".action     = move-column-to-monitor-right;

      # ─ Workspace navigation ─
      "Mod+Page_Down".action      = focus-workspace-down;
      "Mod+Page_Up".action        = focus-workspace-up;
      "Mod+U".action              = focus-workspace-down;
      "Mod+I".action              = focus-workspace-up;
      "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
      "Mod+Ctrl+Page_Up".action   = move-column-to-workspace-up;
      "Mod+Ctrl+U".action         = move-column-to-workspace-down;
      "Mod+Ctrl+I".action         = move-column-to-workspace-up;

      "Mod+Shift+Page_Down".action = move-workspace-down;
      "Mod+Shift+Page_Up".action   = move-workspace-up;
      "Mod+Shift+U".action         = move-workspace-down;
      "Mod+Shift+I".action         = move-workspace-up;

      # ─ Mouse wheel for workspace / column navigation ─
      "Mod+WheelScrollDown"      = { action = focus-workspace-down;       cooldown-ms = 150; };
      "Mod+WheelScrollUp"        = { action = focus-workspace-up;         cooldown-ms = 150; };
      "Mod+Ctrl+WheelScrollDown" = { action = move-column-to-workspace-down; cooldown-ms = 150; };
      "Mod+Ctrl+WheelScrollUp"   = { action = move-column-to-workspace-up;   cooldown-ms = 150; };

      "Mod+WheelScrollRight".action      = focus-column-right;
      "Mod+WheelScrollLeft".action       = focus-column-left;
      "Mod+Ctrl+WheelScrollRight".action = move-column-right;
      "Mod+Ctrl+WheelScrollLeft".action  = move-column-left;

      "Mod+Shift+WheelScrollDown".action      = focus-column-right;
      "Mod+Shift+WheelScrollUp".action        = focus-column-left;
      "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
      "Mod+Ctrl+Shift+WheelScrollUp".action   = move-column-left;

      # ─ Numbered workspaces ─
      "Mod+1".action      = focus-workspace 1;
      "Mod+2".action      = focus-workspace 2;
      "Mod+3".action      = focus-workspace 3;
      "Mod+4".action      = focus-workspace 4;
      "Mod+5".action      = focus-workspace 5;
      "Mod+6".action      = focus-workspace 6;
      "Mod+7".action      = focus-workspace 7;
      "Mod+8".action      = focus-workspace 8;
      "Mod+9".action      = focus-workspace 9;
      # niri-flake quirk: move-column-to-workspace doesn't work as a
      # function call; needs attrset form. See sodiboo/niri-flake#944.
      "Mod+Ctrl+1".action.move-column-to-workspace = [ 1 ];
      "Mod+Ctrl+2".action.move-column-to-workspace = [ 2 ];
      "Mod+Ctrl+3".action.move-column-to-workspace = [ 3 ];
      "Mod+Ctrl+4".action.move-column-to-workspace = [ 4 ];
      "Mod+Ctrl+5".action.move-column-to-workspace = [ 5 ];
      "Mod+Ctrl+6".action.move-column-to-workspace = [ 6 ];
      "Mod+Ctrl+7".action.move-column-to-workspace = [ 7 ];
      "Mod+Ctrl+8".action.move-column-to-workspace = [ 8 ];
      "Mod+Ctrl+9".action.move-column-to-workspace = [ 9 ];

      # ─ Consume / expel ─
      "Mod+BracketLeft".action  = consume-or-expel-window-left;
      "Mod+BracketRight".action = consume-or-expel-window-right;
      "Mod+Comma".action        = consume-window-into-column;
      "Mod+Period".action       = expel-window-from-column;

      # ─ Column / window sizing ─
      "Mod+R".action             = switch-preset-column-width;
      "Mod+Shift+R".action       = switch-preset-column-width-back;
      "Mod+Ctrl+Shift+R".action  = switch-preset-window-height;
      "Mod+Ctrl+R".action        = reset-window-height;

      "Mod+F".action       = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      # "Mod+M".action       = maximize-window-to-edges;
      "Mod+Ctrl+F".action  = expand-column-to-available-width;

      "Mod+C".action      = center-column;
      "Mod+Ctrl+C".action = center-visible-columns;

      "Mod+Minus".action       = set-column-width "-10%";
      "Mod+Equal".action       = set-column-width "+10%";
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      # ─ Floating / layout toggles ─
      "Mod+V".action       = toggle-window-floating;
      "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;
      "Mod+W".action       = toggle-column-tabbed-display;

      # ─ Screenshots ─
      # No Print key on this keyboard; Mod+S triggers built-in UI,
      # Mod+Shift+S uses grim+slurp+satty pipeline for annotation.
      "Mod+S".action.screenshot = {};
      "Mod+Shift+S".action = sh ''
        grim -g "$(slurp -d)" -t ppm - | satty \
          --filename - \
          --output-filename ~/Pictures/Screenshots/Annotated-$(date +%Y%m%d-%H%M%S).png \
          --early-exit \
          --copy-command wl-copy
      '';

      # ─ Inhibit / quit / power ─
      "Mod+Escape" = {
        action = toggle-keyboard-shortcuts-inhibit;
        allow-inhibiting = false;
      };
      "Mod+Shift+E".action     = quit;
      "Ctrl+Alt+Delete".action = quit;
      "Mod+Shift+P".action     = power-off-monitors;
    };
  };
}
