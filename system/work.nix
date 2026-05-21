{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware/work.nix
    ./hardware/workpc_disko.nix
    ../graphical/greetd.nix
    ./desktop.nix
    ../graphical/options.nix
  ];
  environment.systemPackages = with pkgs; [
    clinfo
    cudaPackages.cudatoolkit
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_opencl
  ];
  # Use extra caches for packages
  nix.settings.substituters = [
    "https://nix-community.cachix.org"
    "https://cache.nixos-cuda.org"
  ];
  nix.settings.trusted-public-keys = [
    # Compare to the key published at https://nix-community.org/cache
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = false;
  nixpkgs.config.allowUnfreePredicate =
    p:
    builtins.all (
      license:
      license.free
      || builtins.elem license.shortName [
        "CUDA EULA"
        "cuDNN EULA"
        "cuTENSOR EULA"
        "NVidia OptiX EULA"
      ]
    ) (if builtins.isList p.meta.license then p.meta.license else [ p.meta.license ]);

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.availableKernelModules = [
    "r8169"
  ];
  networking.interfaces.enp4s0.wakeOnLan.enable = true;
  networking.firewall.allowedUDPPorts = [ 9 ];

  # gpu
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };
  hardware.nvidia-container-toolkit.enable = true;
  programs.sway.extraOptions = [ "--unsupported-gpu" ];
  # vulkan
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-tools
    vulkan-headers
    vulkan-loader
  ];

  nix.settings.max-jobs = 10;
  nix.settings.cores = 10;

  networking.hostName = "jmtoepperwienpc";
  system.stateVersion = "25.05"; # Did you read the comment?

  graphical.swayOptions = [ "--unsupported-gpu" ];

  services.logind.settings.Login.HandlePowerKey = "ignore";

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };
}
