{ pkgs, ... }:
{
  # dm-vdo module plus the VDO-enabled LVM userspace tools; required to
  # create and manage the vgwork VDO pool.
  services.lvm.boot.vdo.enable = true;

  # /work lives on the XFS volume (label "work") in the vgwork VDO pool on
  # nvme1n1. Declared here rather than in hardware-configuration.nix so that
  # re-running nixos-generate-config cannot silently drop it: an unmounted
  # /work leaves an empty directory on the root filesystem and every project
  # path under it disappears without an error. Mounted by LV path rather than
  # UUID so the entry survives recreating the volume (the UUID changes, the
  # path doesn't).
  fileSystems."/work" = {
    device = "/dev/vgwork/work";
    fsType = "xfs";
  };

  # /media is a plain (non-VDO) XFS volume in the same volume group: video is
  # already compressed and unique, so dedup/compression gain nothing there, and
  # a plain volume reports honest free space. nofail so the system still boots
  # before the volume exists — it is created by
  # Conversations/vdo-work-setup/split-work-media.sh.
  fileSystems."/media" = {
    device = "/dev/vgwork/media";
    fsType = "xfs";
    options = [ "nofail" "x-systemd.device-timeout=10s" ];
  };

  # Disk administration and recovery tools for the vgwork NVMe.
  environment.systemPackages = with pkgs; [
    nvme-cli
    rsync
    smartmontools
    xfsprogs
  ];
}
