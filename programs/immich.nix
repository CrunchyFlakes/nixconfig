{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.immich = {
    enable = true;
    settings.server.externalDomain = "https://photos.mosi.me/";
  };
  services.nginx.virtualHosts."photos.mosi.me" = {
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };
}
