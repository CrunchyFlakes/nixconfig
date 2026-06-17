{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware/maltepc.nix
    ../graphical/greetd.nix
    ./desktop.nix
  ];
  environment.systemPackages = with pkgs; [
    gnome-boxes
    clinfo
  ];

  hardware.cpu.amd.updateMicrocode = true;
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
  };

  # gpu
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # vulkan
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-tools
    vulkan-headers
    vulkan-loader
    rocmPackages.clr.icd
  ];

  # virtualisation
  virtualisation.virtualbox.host.enable = false;
  users.extraGroups.vboxusers.members = [ "user-with-access-to-virtualbox" ];
  virtualisation.virtualbox.host.enableExtensionPack = true;

  nix.settings.max-jobs = 10;
  nix.settings.cores = 10;

  networking.hostName = "maltepc";

  programs = {
  gamescope = {
    enable = true;
    capSysNice = false;
  };
  steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
};

  system.stateVersion = "22.11"; # Did you read the comment?
}
