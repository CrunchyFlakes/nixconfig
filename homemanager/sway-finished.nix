{ config, lib, pkgs, ... }:

{
  systemd.user.services."sway-finished.target" = {
    enable = false;
    requires = [ "graphical-session.target" ];
    bindsTo = [ "graphical-session.target" ];
  };
}
