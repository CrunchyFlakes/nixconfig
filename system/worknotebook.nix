{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware/worknotebook.nix
    ./hardware/worknotebook_disko.nix
    ../graphical/greetd.nix
    ./desktop.nix
  ];
  environment.systemPackages = with pkgs; [
    clinfo
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

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
  ];

  nix.settings.max-jobs = 10;
  nix.settings.cores = 10;

  networking.hostName = "jmtoepperwiennotebook";

  # power management
  powerManagement.cpuFreqGovernor = "schedutil";

  boot.kernelParams = [
    "amd_pstate=active" # enable amd-pstate-epp driver
  ];

  services.tlp = {
    enable = true;
    settings = {
      # CPU
      CPU_SCALING_GOVERNOR_ON_AC  = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

      CPU_ENERGY_PERF_POLICY_ON_AC  = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_BOOST_ON_AC  = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_HWP_DYN_BOOST_ON_AC  = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Platform profile (Ryzen laptops)
      PLATFORM_PROFILE_ON_AC  = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # NVMe
      DISK_DEVICES         = "nvme0n1";
      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "128 128";
      DISK_IOSCHED          = "none none";
      AHCI_RUNTIME_PM_ON_AC  = "on";
      AHCI_RUNTIME_PM_ON_BAT = "auto";

      # PCIe ASPM
      PCIE_ASPM_ON_AC  = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # WiFi
      WIFI_PWR_ON_AC  = "off";
      WIFI_PWR_ON_BAT = "on";

      # USB autosuspend
      USB_AUTOSUSPEND    = 1;
      USB_EXCLUDE_BTUSB  = 1;
      USB_EXCLUDE_PHONE  = 1;
      USB_EXCLUDE_WWAN   = 1;

      # Runtime PM for PCI devices
      RUNTIME_PM_ON_AC  = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
