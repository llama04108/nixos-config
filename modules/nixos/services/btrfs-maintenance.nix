# modules/nixos/services/btrfs-maintenance.nix
#
# Btrfs filesystem maintenance: monthly scrub to detect bit rot
# via checksums. Single-disk btrfs can DETECT corruption but can't
# REPAIR it (no redundant copy to fall back on); early detection
# is still valuable.
#
# Balance automation is intentionally NOT included — on a
# single-disk SSD workstation it's almost never needed. If
# `btrfs filesystem usage` ever shows large imbalance between
# allocated and used space, run a one-shot:
#   sudo btrfs balance start -dusage=50 -musage=50 /
#
# Hosts running btrfs import this module. Hosts on ext4 (isard)
# or other filesystems don't.

{ ... }:

{
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";

    # Only scrub the topmost mount. Our subvolumes (@, @home,
    # @nix, @swap, @snapshots) all live on the same underlying
    # device — scrubbing each separately would re-read the same
    # blocks multiple times.
    fileSystems = [ "/" ];
  };
}
