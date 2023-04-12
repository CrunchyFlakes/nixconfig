{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltexps.nix
    ../graphical/greetd.nix
    ../graphical/environments-maltexps.nix
    ./desktop.nix
  ];

  services.tlp.enable = true;

  hardware.opengl.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.settings.max-jobs = 4;
  nix.settings.cores = 4;

  networking.hostName = "maltexps";

  # Gnome for touchscreen and beamer setups
  services.xserver.desktopManager.gnome = { # this should not be "xserver" but nix naming conventions are currently like this
    enable = true;
  };

  system.stateVersion = "22.11";
}
