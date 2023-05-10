{ config, lib, pkgs, ... }:

{
  systemd.user.services."nextcloud" = {
    enable = true;
    description = "Nextcloud Client";
    after = [ "sway-finished.service" ];
    partOf = [ "sway-finished.target" ];
    wantedBy = [ "sway-finished.target" ];

    serviceConfig = {
      Type = "simple";
      StandardOutput = "journal";
      ExecStart = "env DISPLAY=':0' QT_QPA_PLATFORM=xcb ${pkgs.nextcloud-client}/bin/nextcloud --background";
    };
  };
}
