{
  config,
  lib,
  pkgs,
  ...
}:

{
  age.secrets."nextcloud-adminpass" = {
    file = ../secrets/nextcloud-adminpass.age;
    owner = "nextcloud";
    group = "nextcloud";
  };
  services.nextcloud = {
    package = pkgs.nextcloud33;
    home = "${config.server.cloud_folder}/nextcloud";
    enable = true;
    https = true;
    hostName = "files.mosi.me";
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      adminpassFile = config.age.secrets."nextcloud-adminpass".path;
      adminuser = "root";
    };
    phpOptions = {
      # defaults
      catch_workers_output = "yes";
      display_errors = "stderr";
      error_reporting = "E_ALL & ~E_DEPRECATED & ~E_STRICT";
      expose_php = "Off";
      "opcache.enable_cli" = "1";
      "opcache.fast_shutdown" = "1";
      "opcache.interned_strings_buffer" = "8";
      "opcache.max_accelerated_files" = "10000";
      "opcache.memory_consumption" = "128";
      "opcache.revalidate_freq" = "1";
      "openssl.cafile" = "/etc/ssl/certs/ca-certificates.crt";
      short_open_tag = "Off";
      # custom
      upload_max_filesize = lib.mkForce "25G";
      post_max_size = lib.mkForce "25G";
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    useACMEHost = "mosi.me";
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}
