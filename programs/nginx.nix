{
  config,
  lib,
  pkgs,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d /var/www 0750 nginx nginx"
  ];
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "m.toepperwien@protonmail.com";
  security.acme.certs."mosihome.duckdns.org".extraDomainNames = [
    "mosigit.duckdns.org"
    "mosiseafile.duckdns.org"
    "mosildap.duckdns.org"
    "mosiphotos.duckdns.org"
  ];
  security.acme.certs."mosi.me".extraDomainNames = [
    "git.mosi.me"
    "files.mosi.me"
    "ldap.mosi.me"
    "photos.mosi.me"
  ];

  users.users.nginx.extraGroups = [ "rtorrent" "media" ];
  services.nginx = {
    enable = true;
    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      ## unsafe-inline needed for arr applications for now
      ## LLDAP still wont work
      #add_header Content-Security-Policy "script-src 'self' 'unsafe-inline'; object-src 'none'; base-uri 'self';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;
    '';
    proxyTimeout = "30m";
    virtualHosts = {
      "jmtoepperwien.com" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/robots.txt" = {
            extraConfig = ''
              rewrite ^/(.*)  $1;
              return 200 "User-agent: *\nDisallow: /";
            '';
          };
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/";
          };
        };
      };
      "mosi.me" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/robots.txt" = {
            extraConfig = ''
              rewrite ^/(.*)  $1;
              return 200 "User-agent: *\nDisallow: /";
            '';
          };
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/";
          };
          "/files/" = {
            root = "/var/www/";
            extraConfig = ''
              access_log /var/log/nginx/public-files.log;
              autoindex on;
              proxy_max_temp_file_size 0;
              aio threads;
              directio 16M;
              output_buffers 2 1M;
              sendfile on;
              sendfile_max_chunk 512k;
            '';
          };
          "/leander/" = {
            root = "/var/www/";
            extraConfig = ''
              disable_symlinks off;
              autoindex on;
              auth_basic           "Leander Serien";
              auth_basic_user_file /etc/nginx/.htpasswd;
              access_log /var/log/nginx/leander-files.log;
              proxy_max_temp_file_size 0;
              aio threads;
              directio 16M;
              output_buffers 2 1M;
              sendfile on;
              sendfile_max_chunk 1M;
              tcp_nopush on;
              tcp_nodelay on;
            '';
          };
          "/sabnzbd/".proxyPass = "http://localhost:6789";
          "/sonarr/".proxyPass = "http://localhost:8989";
          "/radarr/".proxyPass = "http://localhost:7878";
          "/lidarr".proxyPass = "http://localhost:8686";
          "/bazarr".proxyPass = "http://localhost:${toString config.services.bazarr.listenPort}";
          "/readarr/".proxyPass = "http://localhost:8787";
          "/prowlarr/".proxyPass = "http://unix:/run/prowlarr/prowlarr.sock";
          "/navidrome".proxyPass = "http://localhost:3333";
          "/lldap" = {
            proxyPass = "http://localhost:17170";
            extraConfig = ''
              rewrite ^/lldap/(.*) /$1 break;
              rewrite ^/lldap$ / break;
              proxy_redirect ^ /lldap;
              proxy_set_header Accept-Encoding "";
              sub_filter_once off;
              sub_filter_types *;
              sub_filter 'href="/"' 'href="/lldap"';
              sub_filter '\'/pkg/' '\'/lldap/pkg/';
              sub_filter '"static/' '"lldap/static/';
            '';
          };
          "/jellyfin/" = {
            proxyPass = "http://localhost:8096";
            extraConfig = ''
              ## The default `client_max_body_size` is 1M, this might not be enough for some posters, etc.
              client_max_body_size 20M;

              # Disable buffering when the nginx proxy gets very resource heavy upon streaming
              proxy_buffering off;
            '';
          };
          "/jellyfin/socket" = {
            proxyPass = "http://localhost:8096";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };
          "/jellyseerr/" = {
            proxyPass = "http://localhost:5055";
            extraConfig = ''
              set $app 'jellyseerr';

              # Remove /jellyseerr path to pass to the app
              rewrite ^/jellyseerr/?(.*)$ /$1 break;

              # Redirect location headers
              proxy_redirect ^ /$app;
              proxy_redirect /setup /$app/setup;
              proxy_redirect /login /$app/login;

              # Sub filters to replace hardcoded paths
              proxy_set_header Accept-Encoding "";
              sub_filter_once off;
              sub_filter_types *;
              sub_filter '</head>' '<script language="javascript">(()=>{let t="/$app",e=history.pushState;history.pushState=function r(){arguments[2]&&!arguments[2].startsWith(t)&&(arguments[2]=t+arguments[2]);let s=e.apply(this,arguments);return window.dispatchEvent(new Event("pushstate")),s};let r=history.replaceState;function s(){document.querySelectorAll("a[href]").forEach(e=>{let r=e.getAttribute("href");r.startsWith("/")&&!r.startsWith(t)&&e.setAttribute("href",t+r)})}history.replaceState=function e(){arguments[2]&&!arguments[2].startsWith(t)&&(arguments[2]=t+arguments[2]);let s=r.apply(this,arguments);return window.dispatchEvent(new Event("replacestate")),s},document.addEventListener("DOMContentLoaded",function(){let t=new MutationObserver(t=>{t.forEach(t=>{t.addedNodes.length&&s()})});t.observe(document.body,{childList:!0,subtree:!0}),s()})})();</script></head>';
              sub_filter 'href="/"' 'href="/$app"';
              sub_filter 'href="/login"' 'href="/$app/login"';
              sub_filter 'href:"/"' 'href:"/$app"';
              sub_filter '\/_next' '\/$app\/_next';
              sub_filter '/_next' '/$app/_next';
              sub_filter '/api/v1' '/$app/api/v1';
              sub_filter '/login/plex/loading' '/$app/login/plex/loading';
              sub_filter '/images/' '/$app/images/';
              sub_filter '/imageproxy/' '/$app/imageproxy/';
              sub_filter '/avatarproxy/' '/$app/avatarproxy/';
              sub_filter '/android-' '/$app/android-';
              sub_filter '/apple-' '/$app/apple-';
              sub_filter '/favicon' '/$app/favicon';
              sub_filter '/logo_' '/$app/logo_';
              sub_filter '/site.webmanifest' '/$app/site.webmanifest';
            '';
          };
          "/autobrr/" = {
            proxyPass = "http://localhost:7474";
            extraConfig = ''
              rewrite ^/autobrr/(.*)$ /$1 break;
            '';
          };
          "/flood/".proxyPass = "http://localhost:5678";
          "/grafana/" = {
            proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
      };
      "git.mosi.me" = {
        forceSSL = true;
        useACMEHost = "mosi.me";
        locations = {
          "/robots.txt" = {
            extraConfig = ''
              rewrite ^/(.*)  $1;
              return 200 "User-agent: *\nDisallow: /";
            '';
          };
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/";
          };
          "/" = {
            proxyPass = "http://localhost:3000/";
          };
        };
      };
      "ldap.mosi.me" = {
        forceSSL = true;
        useACMEHost = "mosi.me";
        locations = {
          "/".proxyPass = "http://localhost:17170";
          "/robots.txt" = {
            extraConfig = ''
              rewrite ^/(.*)  $1;
              return 200 "User-agent: *\nDisallow: /";
            '';
          };
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/";
          };
        };
      };
      "files.mosi.me" = {
        forceSSL = true;
        useACMEHost = "mosi.me";
        locations = {
          "/robots.txt" = {
            extraConfig = ''
              rewrite ^/(.*)  $1;
              return 200 "User-agent: *\nDisallow: /";
            '';
          };
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/";
          };
        };
      };
      "photos.mosi.me" = {
        forceSSL = true;
        useACMEHost = "mosi.me";
        locations = {
          "/robots.txt" = {
            extraConfig = ''
              rewrite ^/(.*)  $1;
              return 200 "User-agent: *\nDisallow: /";
            '';
          };
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/";
          };
        };
      };

      "mosihome.duckdns.org" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/acme-challenge";
          };
          "/" = {
            extraConfig = ''
              return 301 https://mosi.me$request_uri;
            '';
          };
        };
      };
      "mosigit.duckdns.org" = {
        forceSSL = true;
        useACMEHost = "mosihome.duckdns.org";
        locations = {
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/acme-challenge";
          };
          "/" = {
            extraConfig = ''
              return 301 https://git.mosi.me$request_uri;
            '';
          };
        };
      };
      "mosiseafile.duckdns.org" = {
        forceSSL = true;
        useACMEHost = "mosihome.duckdns.org";
        locations = {
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/acme-challenge";
          };
          "/" = {
            extraConfig = ''
              return 301 https://files.mosi.me$request_uri;
            '';
          };
        };
      };
      "mosildap.duckdns.org" = {
        forceSSL = true;
        useACMEHost = "mosihome.duckdns.org";
        locations = {
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/acme-challenge";
          };
          "/" = {
            extraConfig = ''
              return 301 https://ldap.mosi.me$request_uri;
            '';
          };
        };
      };
      "mosiphotos.duckdns.org" = {
        forceSSL = true;
        useACMEHost = "mosihome.duckdns.org";
        locations = {
          "/.well-known/acme-challenge" = {
            root = "/var/lib/acme/acme-challenge";
          };
          "/" = {
            extraConfig = ''
              return 301 https://photos.mosi.me$request_uri;
            '';
          };
        };
      };

      "192.168.1.234" = {
        forceSSL = false;
        locations = {
          "/RPC2" = {
            extraConfig = ''
              include ${pkgs.nginx}/conf/scgi_params;
              scgi_pass unix:/run/rtorrent/rpc.sock;
            '';
          };
          "/sabnzbd/".proxyPass = "http://localhost:6789";
          "/sonarr/".proxyPass = "http://localhost:8989";
          "/radarr/".proxyPass = "http://localhost:7878";
          "/lidarr".proxyPass = "http://localhost:8686";
          "/readarr/".proxyPass = "http://localhost:8787";
          "/prowlarr/".proxyPass = "http://unix:/run/prowlarr/prowlarr.sock";
          "/navidrome".proxyPass = "http://localhost:3333";
          "/lldap" = {
            proxyPass = "http://localhost:17170";
            extraConfig = ''
              rewrite ^/lldap/(.*) /$1 break;
              rewrite ^/lldap$ / break;
              proxy_redirect ^ /lldap;
              proxy_set_header Accept-Encoding "";
              sub_filter_once off;
              sub_filter_types *;
              sub_filter 'href="/"' 'href="/lldap"';
              sub_filter '\'/pkg/' '\'/lldap/pkg/';
              sub_filter '"static/' '"lldap/static/';
            '';

          };
          "/jellyfin/" = {
            proxyPass = "http://localhost:8096";
            extraConfig = ''
              ## The default `client_max_body_size` is 1M, this might not be enough for some posters, etc.
              client_max_body_size 20M;

              # Disable buffering when the nginx proxy gets very resource heavy upon streaming
              proxy_buffering off;
            '';
          };
          "/jellyfin/socket" = {
            proxyPass = "http://localhost:8096";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };
          "/jellyseerr/" = {
            proxyPass = "http://localhost:5055";
            extraConfig = ''
              set $app 'jellyseerr';

              # Remove /jellyseerr path to pass to the app
              rewrite ^/jellyseerr/?(.*)$ /$1 break;

              # Redirect location headers
              proxy_redirect ^ /$app;
              proxy_redirect /setup /$app/setup;
              proxy_redirect /login /$app/login;

              # Sub filters to replace hardcoded paths
              proxy_set_header Accept-Encoding "";
              sub_filter_once off;
              sub_filter_types *;
              sub_filter '</head>' '<script language="javascript">(()=>{let t="/$app",e=history.pushState;history.pushState=function r(){arguments[2]&&!arguments[2].startsWith(t)&&(arguments[2]=t+arguments[2]);let s=e.apply(this,arguments);return window.dispatchEvent(new Event("pushstate")),s};let r=history.replaceState;function s(){document.querySelectorAll("a[href]").forEach(e=>{let r=e.getAttribute("href");r.startsWith("/")&&!r.startsWith(t)&&e.setAttribute("href",t+r)})}history.replaceState=function e(){arguments[2]&&!arguments[2].startsWith(t)&&(arguments[2]=t+arguments[2]);let s=r.apply(this,arguments);return window.dispatchEvent(new Event("replacestate")),s},document.addEventListener("DOMContentLoaded",function(){let t=new MutationObserver(t=>{t.forEach(t=>{t.addedNodes.length&&s()})});t.observe(document.body,{childList:!0,subtree:!0}),s()})})();</script></head>';
              sub_filter 'href="/"' 'href="/$app"';
              sub_filter 'href="/login"' 'href="/$app/login"';
              sub_filter 'href:"/"' 'href:"/$app"';
              sub_filter '\/_next' '\/$app\/_next';
              sub_filter '/_next' '/$app/_next';
              sub_filter '/api/v1' '/$app/api/v1';
              sub_filter '/login/plex/loading' '/$app/login/plex/loading';
              sub_filter '/images/' '/$app/images/';
              sub_filter '/imageproxy/' '/$app/imageproxy/';
              sub_filter '/avatarproxy/' '/$app/avatarproxy/';
              sub_filter '/android-' '/$app/android-';
              sub_filter '/apple-' '/$app/apple-';
              sub_filter '/favicon' '/$app/favicon';
              sub_filter '/logo_' '/$app/logo_';
              sub_filter '/site.webmanifest' '/$app/site.webmanifest';
            '';
          };
          "/autobrr/" = {
            proxyPass = "http://localhost:7474";
            extraConfig = ''
              rewrite ^/autobrr/(.*)$ /$1 break;
            '';
          };

          "/flood/".proxyPass = "http://localhost:5678";
          "/tempfiles/" = {
            root = "/var/www";
            extraConfig = ''
              disable_symlinks off;
              allow 192.168.1.0/24;
              deny all;
              autoindex on;
              aio threads;
              sendfile on;
              sendfile_max_chunk 1M;
              tcp_nopush on;
              tcp_nodelay on;
            '';
          };
        };
      };
      "pi4.home.lan" = {
        forceSSL = false;
        locations = {
          "/books/" = {
            root = "/export/";
            extraConfig = ''
              disable_symlinks off;
              allow 192.168.1.0/24;
              deny all;
              autoindex on;
              proxy_max_temp_file_size 0;
              aio threads;
              directio 16M;
              output_buffers 2 1M;
              sendfile on;
              sendfile_max_chunk 1M;
              tcp_nopush on;
              tcp_nodelay on;
            '';
          };
          "/otherfiles/" = {
            root = "/export/";
            extraConfig = ''
              disable_symlinks off;
              allow 192.168.1.0/24;
              deny all;
              autoindex on;
              proxy_max_temp_file_size 0;
              aio threads;
              directio 16M;
              output_buffers 2 1M;
              sendfile on;
              sendfile_max_chunk 1M;
              tcp_nopush on;
              tcp_nodelay on;
            '';
          };
          "/RPC2" = {
            extraConfig = ''
              include ${pkgs.nginx}/conf/scgi_params;
              scgi_pass unix:/run/rtorrent/rpc.sock;
            '';
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
