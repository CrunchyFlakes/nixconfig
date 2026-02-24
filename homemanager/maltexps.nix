{ config, pkgs, ... }:

{
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "22.11";

  imports = [
    ./desktop.nix
    ./laptop.nix
  ];

  home.packages = with pkgs; [
    rnote
  ];

  home.file.".config/sway/config" = {
    text = ''
      include maltexps
      include common
      include nix-managed
    '';
  };
}
