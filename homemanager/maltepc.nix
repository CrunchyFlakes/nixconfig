{ config, pkgs, ... }:

{
  home.username = "mtoepperwien";
  home.homeDirectory = "/home/mtoepperwien";
  home.stateVersion = "22.11";

  imports = [
    ./desktop.nix
  ];

  home.packages = with pkgs; [
    btop-rocm
    # Gaming {{{
    rusty-path-of-building
    # lutris notes
    # anno 1800
    # ubisoft connect "connection lost" -> "echo 2 | sudo tee /proc/sys/net/ipv4/tcp_mtu_probing"
    # ubisoft connect "looking for patches" -> disable esync and fsync (reenable afterwards)
    (lutris.override {
      extraPkgs = pkgs: [
        pkgsi686Linux.gnutls
        gnutls
        vulkan-tools
        vulkan-headers
        vulkan-loader
        mangohud
      ];
    })
    # wine
    wineWowPackages.stagingFull
    winetricks
    # }}} Gaming
  ];

  home.file.".config/sway/config" = {
    text = ''
      include maltepc
      include common
      include nix-managed
    '';
  };

  programs.kitty.font.size = 15;
}
