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

  fileSystems."/mnt/pi4/books" = {
    device = "${pi4ip}:/export/books";
    fsType = "nfs";
  };

  fileSystems."/mnt/pi4/series" = {
    device = "${pi4ip}:/export/series";
    fsType = "nfs";
  };

  fileSystems."/mnt/pi4/movies" = {
    device = "${pi4ip}:/export/movies";
    fsType = "nfs";
  };


  swapDevices = [ ];

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
