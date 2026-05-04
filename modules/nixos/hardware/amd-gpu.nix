# modules/nixos/hardware/amd-gpu.nix
#
# AMD GPU support: Mesa graphics stack with RADV Vulkan, 32-bit
# libraries for Steam/Proton/Wine, optional ROCm/HIP for compute
# workloads (Blender Cycles, ML inference, GPU-accelerated apps).
#
# Hosts opt into ROCm separately because the closure is large
# (~1.5GB) and only useful for compute. A pure-gaming AMD host
# wants graphics but not ROCm.

{ config, lib, pkgs, ... }:

let
  cfg = config.local.hardware.amdGpu;
in
{
  # ─── Options ────────────────────────────────────────────────────────
  options.local.hardware.amdGpu = {
    rocm.enable = lib.mkEnableOption ''
      ROCm/HIP support for compute workloads. Adds rocBLAS, hipBLAS,
      and the OpenCL ICD (~1.5GB closure). Creates /opt/rocm symlink
      that some HIP apps (notably Blender) hardcode-search for.
      Skip on pure-gaming hosts.
    '';
  };

  # ─── Configuration ──────────────────────────────────────────────────
  # mkMerge combines multiple config attrsets — the always-on base
  # and the conditional ROCm bits — into one merged contribution.
  config = lib.mkMerge [

    # Always-on base: every host that imports this module gets these.
    {
      hardware.amdgpu.initrd.enable = true;

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd
        ];
      };

      environment.variables = {
        AMD_VULKAN_ICD = "RADV";
      };
    }

    # ROCm-only: only applied when local.hardware.amdGpu.rocm.enable
    # is true. The /opt/rocm symlink lets apps that hardcode that
    # path (Blender, some ML frameworks) find a working ROCm install.
    (lib.mkIf cfg.rocm.enable {
      systemd.tmpfiles.rules = let
        rocmEnv = pkgs.symlinkJoin {
          name = "rocm-combined";
          paths = with pkgs.rocmPackages; [ rocblas hipblas clr ];
        };
      in [ "L+ /opt/rocm - - - - ${rocmEnv}" ];
    })
  ];
}
