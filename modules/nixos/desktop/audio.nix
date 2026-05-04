# modules/nixos/desktop/audio.nix
#
# PipeWire-based audio stack with optional low-latency tuning for
# music production (Bitwig, Reaper, LinnStrument, hardware MIDI).
#
# Hosts opt in via:
#   local.audio.lowLatency.enable = true;
#
# Defaults are tuned for sloane's use case (quantum=64 at 48kHz).
# Hosts that want different settings override the option values.

{ config, lib, pkgs, ... }:

let
  # `cfg` is convention — shorthand for "the configured values for
  # this module's options." Lets us write `cfg.enable` instead of
  # `config.local.audio.lowLatency.enable` everywhere below.
  cfg = config.local.audio.lowLatency;
in
{
  # ─── Options ────────────────────────────────────────────────────────
  # The knobs this module exposes. Setting these in a host file
  # changes the module's behavior.
  options.local.audio.lowLatency = {
    enable = lib.mkEnableOption "low-latency audio stack (PipeWire + RT)";

    sampleRate = lib.mkOption {
      type = lib.types.int;
      default = 48000;
      description = ''
        Default PipeWire sample rate in Hz. 48000 is the standard for
        music production and works well with most hardware. Use 44100
        only if you specifically need it (CD-rate work).
      '';
    };

    quantum = lib.mkOption {
      type = lib.types.int;
      default = 64;
      description = ''
        Default PipeWire quantum (buffer size) in frames. Lower values
        reduce latency but increase CPU load and risk of xruns.
        At 48kHz: 64 frames ≈ 1.3ms; 128 ≈ 2.7ms; 256 ≈ 5.3ms.
        Start at 64. If xruns occur during heavy plugin loads, raise
        to 128.
      '';
    };

    minQuantum = lib.mkOption {
      type = lib.types.int;
      default = 32;
      description = "Minimum quantum the audio stack will negotiate.";
    };

    maxQuantum = lib.mkOption {
      type = lib.types.int;
      default = 512;
      description = "Maximum quantum the audio stack will negotiate.";
    };
  };

  # ─── Configuration ──────────────────────────────────────────────────
  # `lib.mkIf cfg.enable` means: only contribute these settings when
  # the module is enabled. When disabled, this entire block is
  # invisible to the module merger.
  config = lib.mkIf cfg.enable {

    # rtkit grants real-time scheduling priority to processes that
    # request it (and are allowed). Required for low-latency audio.
    security.rtkit.enable = true;

    # PAM limits for the @audio group. Members of this group get:
    #   - rtprio 99: maximum real-time scheduling priority
    #   - memlock unlimited: can lock memory pages (prevents paging
    #     of audio buffers, which would cause xruns)
    #   - nice -20: highest non-RT scheduling priority
    # Users who need low-latency audio must be in the audio group
    # (set via users.users.<name>.extraGroups in the host file).
    security.pam.loginLimits = [
      { domain = "@audio"; type = "-"; item = "rtprio";  value = "99"; }
      { domain = "@audio"; type = "-"; item = "memlock"; value = "unlimited"; }
      { domain = "@audio"; type = "-"; item = "nice";    value = "-20"; }
    ];

    # PipeWire as the audio server. Replaces PulseAudio + JACK with
    # a single daemon that speaks all three protocols.
    services.pipewire = {
      enable = true;

      # Compatibility shims so apps written for older audio APIs
      # (PulseAudio clients, ALSA-only apps, JACK clients) work
      # transparently.
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;

      # Low-latency tuning. The string keys match PipeWire's config
      # file naming convention; NixOS writes these to
      # /etc/pipewire/pipewire.conf.d/99-lowlatency.conf
      extraConfig.pipewire = {
        "99-lowlatency" = {
          context.properties = {
            default.clock.rate        = cfg.sampleRate;
            default.clock.quantum     = cfg.quantum;
            default.clock.min-quantum = cfg.minQuantum;
            default.clock.max-quantum = cfg.maxQuantum;
          };
        };
      };
    };
  };
}
