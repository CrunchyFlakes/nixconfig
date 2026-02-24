{ config, pkgs, ... }:

{
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "25.05";

  imports = [
    ./desktop.nix
    ./work.nix
    ./laptop.nix
  ];

  home.packages = with pkgs; [
  ];

  home.file.".config/sway/config" = {
    text = ''
      include worknotebook
      include common
      include nix-managed
    '';
  };
}
