# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:
let
  pi4ip = "192.168.1.234";
in {
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # more gpu stuff
  systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.hip}"
    ];
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
  environment.systemPackages = with pkgs; [ rocm-runtime rocm-device-libs rocm-core rocm-smi rocminfo ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/0ef999fd-b03a-47eb-8c9b-373f7a391d77";
      fsType = "btrfs";
      options = [ "subvol=@"  "defaults" ];
    };

  boot.initrd.luks.devices."root" = {
    device = "/dev/disk/by-uuid/f97e6697-110c-4d82-ab82-f5129e937aeb";
    allowDiscards = true;
  };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/0ef999fd-b03a-47eb-8c9b-373f7a391d77";
      fsType = "btrfs";
      options = [ "subvol=@home" "defaults" ];
    };

  fileSystems."/var" =
    { device = "/dev/disk/by-uuid/0ef999fd-b03a-47eb-8c9b-373f7a391d77";
      fsType = "btrfs";
      options = [ "subvol=@var" "defaults" ];
    };

  fileSystems."/var/lib" =
    { device = "/dev/disk/by-uuid/0ef999fd-b03a-47eb-8c9b-373f7a391d77";
      fsType = "btrfs";
      options = [ "subvol=@varlib" "defaults" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/66FF-13D9";
      fsType = "vfat";
    };

  services.rpcbind.enable = true; # needed for NFS
  fileSystems."/mnt/pi4/books" = {
    device = "${pi4ip}:/export/books";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600s" ];
  };

  fileSystems."/mnt/pi4/series" = {
    device = "${pi4ip}:/export/series";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600s" ];
  };

  fileSystems."/mnt/pi4/movies" = {
    device = "${pi4ip}:/export/movies";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600s" ];
  };


  swapDevices = [ {
    device = "/swapfile";
    size = 16 * 1024;
  } ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
