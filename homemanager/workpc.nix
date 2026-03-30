{ config, pkgs, inputs, nixpkgs-unstable, ... }:

let
  pkgs-unstable = import nixpkgs-unstable { system = pkgs.system; config.allowUnfree = true; };
in {
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "25.05";

  imports = [
    ./desktop.nix
    ./work.nix
  ];

  home.packages = [
    pkgs-unstable.ollama-cuda
    pkgs.btop-cuda
  ];

  home.file.".config/sway/config" = {
    text = ''
      include workpc
      include common
      include nix-managed
    '';
  };

  programs.kitty.font.size = 12;
}
