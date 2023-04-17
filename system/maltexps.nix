{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltexps.nix
    ../graphical/greetd.nix
    ../graphical/environments-maltexps.nix
    ./desktop.nix
  ];

  services.tlp.enable = true;

  hardware.cpu.intel.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      vulkan-tools
      vulkan-headers
      vulkan-loader
    ];
  };

  nix.settings.max-jobs = 4;
  nix.settings.cores = 4;

  networking.hostName = "maltexps";

  # Gnome for touchscreen and beamer setups
  services.xserver.desktopManager.gnome = { # this should not be "xserver" but nix naming conventions are currently like this
    enable = true;
  };
  # disable this to use tlp as it seems to be better
  services.power-profiles-daemon.enable = false;
  # disable this to use pipewire instead
  hardware.pulseaudio.enable = false;

  system.stateVersion = "22.11";
}
