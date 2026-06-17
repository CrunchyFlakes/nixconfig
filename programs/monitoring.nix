{
  config,
  lib,
  pkgs,
  inputs,
  agenix,
  ...
}:

{
  services.prometheus = {
    enable = false;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
        ];
        port = 9000;
      };
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = false;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3344;
        domain = "mosi.me";
        root_url = "http://mosi.me/grafana/";
        serve_from_sub_path = true;
      };
    };
  };
}
