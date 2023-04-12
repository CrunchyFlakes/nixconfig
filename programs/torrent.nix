{ config, lib, pkgs, agenix, ... }:

{
  users.groups."rtorrent" = {};
  users.users."rtorrent" = {
    isSystemUser = true;
    group = "rtorrent";
    extraGroups= [ "usenet" ];
  };

  environment.systemPackages = [ pkgs.flood ];

  services.rtorrent = {
    enable = true;
    user = "rtorrent";
    dataPermissions = "0775";
    downloadDir = "/mnt/kodi_lib/downloads_torrent";
  };

  systemd.services.rtorrent = let
      configFile = pkgs.writeText "rtorrent.rc" config.services.rtorrent.configText;
    in {
      bindsTo = [ "netns@vpn.service" ];
      requires = [ "network-online.target" ];
      after = [ "protonvpn.service" ];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/vpn";
        ExecStart = "${pkgs.tmux}/bin/tmux -L rt new-session -s rt -n rtorrent -d rtorrent ${pkgs.rtorrent}/bin/rtorrent -n -o import=${configFile}";
        ExecStop = "${pkgs.bash}/bin/bash -c \"${pkgs.tmux}/bin/tmux -L rt send-keys -t rt:rtorrent.0 C-q; while pidof rtorrent > /dev/null; do echo stopping rtorrent...; sleep 1; done\"";
      };
    };

  systemd.services.flood = {
    enable = true;
    description = "Flood frontend for rtorrent";
    bindsTo = [ "rtorrent.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.flood}/bin/flood --rtsocket /run/rtorrent/rpc.sock --port 5678 --host 0.0.0.0";
      Restart = "on-failure";
      Type = "simple";
      User = "rtorrent";
      Group = "rtorrent";
    };
  };
  networking.firewall.allowedTCPPorts = [ 5678 ];
}
