{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware/server_disko.nix
  ];

  boot = {
    initrd.supportedFilesystems = [ "zfs" ];
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      forceImportAll = false;
      devNodes = "/dev/disk/by-path";
    };
    kernel.sysctl = {
      # networking tweaks (bigger buffers)
      "net.core.rmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 12582912 16777216";
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_wmem" = "4096 12582912 16777216";
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_tw_recycle" = 1;
      "net.ipv4.tcp_fin_timeout" = 30;
    };
  };

  services.zfs.autoScrub.enable = true;

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    systemd-boot.enable = true;
  };

  #sound.enable = true;
  #hardware.pulseaudio.enable = true;
  # sound settings
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = false;
  };
  environment.systemPackages = [
    pkgs.pulsemixer
    pkgs.alsa-utils
    pkgs.mediainfo
    pkgs.fuse
  ];

  age.secrets.wifipassword.file = ../secrets/wifipassword.age;
  networking = {
    hostId = "1eb062bf";
    hostName = "server"; # Define your hostname.
    firewall.enable = true;
    nftables.enable = true;
    firewall.allowedTCPPorts = [ 53589 ];
    wireless = {
      enable  = true;
      secretsFile = config.age.secrets.wifipassword.path;
      userControlled.enable = true;
      networks."Mosi".pskRaw = "ext:mosi_pskraw";
    };
    networkmanager.enable = false;
  };

  users.groups.mtoepperwien = { };
  users.users.mtoepperwien = {
    isNormalUser = true;
    group = "mtoepperwien";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "usenet"
      "rtorrent"
    ];
    openssh.authorizedKeys.keyFiles = [
      ../authorized_keys
    ];
    initialHashedPassword = "$y$j9T$lHlU2dP/P0DpciBq98Vq1/$zvzvVNzmzjrgWepOP7f2OC0keKPtxfGr/bzpL1UONh2";
  };
  users.users.root.initialHashedPassword = "$y$j9T$lHlU2dP/P0DpciBq98Vq1/$zvzvVNzmzjrgWepOP7f2OC0keKPtxfGr/bzpL1UONh2";

  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };

  # locations
  systemd.tmpfiles.rules = [
    "d ${config.server.media_folder} 0770 mtoepperwien media"
    "d ${config.server.git_folder} 0770 ${config.services.gitea.user} ${config.services.gitea.group}"
    "d ${config.server.cloud_folder} 0770 mtoepperwien cloud"
  ];

  system.stateVersion = "24.11";
}
