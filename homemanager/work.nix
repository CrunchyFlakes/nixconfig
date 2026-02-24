{ config, pkgs, ... }:

{
  imports = [
    ./desktop.nix
  ];

  home.packages = with pkgs; [
    mattermost-desktop
  ];

  home.stateVersion = "25.05";

  home.file.".config/sway/config" = {
    text = ''
      include workpc
      include common
      include nix-managed
    '';
  };

  programs.git.settings.user.email = "m.toepperwien@ai.uni-hannover.de";
}
