# modules/nixos/hardware/intel-cpu.nix
#
# Intel CPU hardware support. Microcode updates and frequency
# governor selection appropriate for hybrid-architecture chips
# (P-cores + E-cores, 12th gen and newer).

{ ... }:

{
  # ─── Microcode ──────────────────────────────────────────────────────
  # Intel ships CPU firmware updates ("microcode") for security fixes
  # and errata. Without this, you miss mitigations for vulnerabilities
  # like Spectre/Meltdown variants, plus stability fixes specific to
  # your CPU stepping. Loaded at boot via initrd.
  hardware.cpu.intel.updateMicrocode = true;

  # ─── Frequency governor ─────────────────────────────────────────────
  # schedutil: scheduler-driven governor that ramps frequency based
  # on actual scheduler demand. Plays well with Intel's hybrid
  # P-core/E-core scheduling on 12th-14th gen — the kernel's
  # Intel Thread Director hints get respected.
  #
  # Alternatives: 'performance' (always max clock, hot/loud),
  # 'powersave' (with intel_pstate=passive, surprisingly OK on
  # newer hardware). schedutil is the modern default and the right
  # choice for desktop workloads where you want responsiveness
  # without thermal nonsense.
  powerManagement.cpuFreqGovernor = "schedutil";
}
