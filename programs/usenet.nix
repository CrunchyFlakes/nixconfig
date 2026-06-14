{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = [ pkgs.par2cmdline ];
  users.groups."media" = { };

  # Sonarr
  users.groups."sonarr" = { };
  users.users."sonarr" = {
    isSystemUser = true;
    group = "sonarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };

  services.sonarr = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.sonarr;
    openFirewall = true;
  };

  # Radarr
  users.groups."radarr" = { };
  users.users."radarr" = {
    isSystemUser = true;
    group = "radarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };

  services.radarr = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.radarr;
    openFirewall = true;
  };

  # Lidarr
  users.groups."lidarr" = { };
  users.users."lidarr" = {
    isSystemUser = true;
    group = "lidarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };

  services.lidarr = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.lidarr;
    openFirewall = true;
  };

  # Bazarr
  users.groups."bazarr" = { };
  users.users."bazarr" = {
    isSystemUser = true;
    group = "bazarr";
    extraGroups = [
      "media"
    ];
  };

  services.bazarr = {
    enable = true;
    openFirewall = true;
  };

  # Readarr
  users.groups."readarr" = { };
  users.users."readarr" = {
    isSystemUser = true;
    group = "readarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };

  services.readarr = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.readarr;
    openFirewall = true;
  };
  ## Calibre Server for Readarr
  services.calibre-server = {
    enable = false;
    user = "readarr";
    group = "readarr";
    libraries = [ "${config.server.media_folder}/books/" ];
  };

  # Prowlarr
  users.groups."prowlarr" = { };
  users.users."prowlarr" = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [
      "media"
      "rtorrent"
    ];
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.prowlarr = {
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpn";
    };
  };
  systemd.tmpfiles.rules = [
    "d /run/prowlarr 0755 prowlarr prowlarr"
    "d ${config.server.media_folder}/downloads/nzb 0750 sabnzbd media"
    "d ${config.server.media_folder}/downloads/nzb/temporary 0750 sabnzbd media"
    "d ${config.server.media_folder}/downloads/nzb/completed 0750 sabnzbd media"
  ];
  systemd.services.prowlarrforward = {
    bindsTo = [ "netns-vpn.service" ];
    requires = [ "protonvpn.service" ];
    after = [ "protonvpn.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = ''
        ${pkgs.socat}/bin/socat UNIX-LISTEN:/run/prowlarr/prowlarr.sock,fork,umask=0007 TCP:localhost:9696
      '';
      Type = "simple";
      User = "prowlarr";
      Group = "nginx";
    };
  };

  # Sabnzbd
  users.users."sabnzbd" = {
    isSystemUser = true;
    group = lib.mkForce "media";
  };

  services.sabnzbd = {
    enable = true;
    group = "media";
  };
  networking.firewall.allowedTCPPorts = [ 6789 ];
}
