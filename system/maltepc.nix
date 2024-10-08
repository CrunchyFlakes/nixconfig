{ config, lib, modulesPath, pkgs, ... }:

{
  imports = [
    ./hardware/maltepc.nix
    ../graphical/greetd.nix
    ./desktop.nix
  ];
  environment.systemPackages = with pkgs; [
    virt-manager
    virtiofsd
    gnome.gnome-boxes
  ];

  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # gpu
  hardware.opengl.enable = true;
  # vulkan
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [ 
    vulkan-tools
    vulkan-headers
    vulkan-loader
  ];

  # virtualisation
  virtualisation.virtualbox.host.enable = false;
  users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];
  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  nix.settings.max-jobs = 6;
  nix.settings.cores = 6;

  networking.hostName = "maltepc";

  system.stateVersion = "22.11"; # Did you read the comment?
}
