{
  config,
  pkgs,
  lib,
  ...
}:

let
  socketPath = "/run/continuwuity/continuwuity.sock";
in
{
  services.nginx.upstreams.continuwuity = {
    servers."unix:${socketPath}" = { };
  };
  services.matrix-continuwuity = {
    enable = true;
    settings = {
      global = {
        server_name = "mosi.me";
        allow_registration = false;
        allow_encryption = true;
        allow_federation = true;
        trusted_servers = [ "matrix.org" ];
        address = null;
        unix_socket_path = socketPath;
        unix_socket_perms = 660;
      };
    };
  };

  # nginx needs access to the unix socket
  users.users.nginx.extraGroups = [ "continuwuity" ];

  # Single cert covering both the bare domain (for .well-known) and the matrix subdomain
  security.acme.certs."mosi.me" = {
    extraDomainNames = [ "matrix.mosi.me" ];
  };

  # Bare domain: serves .well-known delegation only
  services.nginx.virtualHosts."mosi.me" = {
    locations = {
      "= /.well-known/matrix/server" = {
        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin * always;
          add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload" always;
          add_header Referrer-Policy "origin-when-cross-origin" always;
          add_header X-Frame-Options DENY always;
          add_header X-Content-Type-Options nosniff always;
          return 200 '{"m.server":"matrix.mosi.me:443"}';
        '';
      };
      "= /.well-known/matrix/support" = {
        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin * always;
          add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload" always;
          add_header Referrer-Policy "origin-when-cross-origin" always;
          add_header X-Frame-Options DENY always;
          add_header X-Content-Type-Options nosniff always;
          return 200 '{"contacts":[]}';
        '';
      };
      "= /.well-known/matrix/client" = {
        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin * always;
          add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload" always;
          add_header Referrer-Policy "origin-when-cross-origin" always;
          add_header X-Frame-Options DENY always;
          add_header X-Content-Type-Options nosniff always;
          return 200 '{"m.homeserver":{"base_url":"https://matrix.mosi.me"}}';
        '';
      };
    };
  };
  # matrix subdomain: proxies the actual Matrix API
  services.nginx.virtualHosts."matrix.mosi.me" = {
    forceSSL = true;
    useACMEHost = "mosi.me";
    locations = {
      "/_matrix/" = {
        proxyPass = "http://continuwuity$request_uri";
        extraConfig = ''
          client_max_body_size 50M;
        '';
      };
      "/_continuwuity/" = {
        proxyPass = "http://continuwuity$request_uri";
      };
      "/_conduwuit/" = {
        proxyPass = "http://continuwuity$request_uri";
      };
    };
  };
}
