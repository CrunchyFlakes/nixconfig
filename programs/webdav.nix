{
 config,
  lib,
  pkgs,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d ${config.server.cloud_folder}/dav 0700 ${config.services.webdav.user} ${config.services.webdav.group}"
  ];
  age.secrets.webdav = {
    file = ../secrets/webdav.age;
    owner = "${config.services.webdav.user}";
    group = "${config.services.webdav.group}";
  };
  users.users."${config.services.webdav.user}".extraGroups = [ "cloud" ];
  services.webdav = {
    enable = true;
    settings = {
      directory = "${config.server.cloud_folder}/dav";
      address = "0.0.0.0";
      port = 8765;
      scope = "/srv/public";
      prefix = "/webdav";
      modify = true;
      auth = true;
      debug = true;
      users = [
        {
          username = "{env}ENV_USERNAME";
          password = "{env}ENV_PASSWORD";
          permissions = "CRUD";
        }
      ];
    };
    environmentFile = "${config.age.secrets.webdav.path}";
  };
  services.nginx.virtualHosts."mosi.me" = {
    locations = {
      "/webdav/" = {
        proxyPass = "http://localhost:${toString config.services.webdav.settings.port}";
        extraConfig = ''
          client_max_body_size 0;
          proxy_connect_timeout  36000s;
          proxy_read_timeout  36000s;
          proxy_send_timeout  36000s;
          send_timeout  36000s;
        '';
      };
    };
  };


}
