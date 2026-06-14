{
  config,
  lib,
  pkgs,
  agenix,
  inputs,
  ...
}:
{
  systemd.tmpfiles.rules = [ "d ${config.server.media_folder}/music 0755 lidarr lidarr" ];
  services.navidrome = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.navidrome;
    settings = {
      Address = "0.0.0.0";
      Port = 3333;
      MusicFolder = "${config.server.media_folder}/music";
      BaseUrl = "/navidrome";
    };
  };
}
