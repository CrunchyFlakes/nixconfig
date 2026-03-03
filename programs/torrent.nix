{
  config,
  lib,
  pkgs,
  inputs,
  agenix,
  ...
}:
let
  cross-seedHook = pkgs.writeShellScriptBin "cross-seed-hook" ''
    source ${config.age.secrets.cross-seed.path}
    ${pkgs.curl}/bin/curl -XPOST http://127.0.0.1:2468/api/webhook \
      -H "X-Api-Key: ''${apikey}" \
      --data-urlencode "infoHash=$1" \
      --data-urlencode 'includeSingleEpisodes=true'
  '';
  autotorrent2Config = pkgs.writeText "at2config" ''
    [autotorrent]
    database_path = "/var/lib/rtorrent/autotorrent.db"
    link_type = "hard"
    always_verify_hash = [
        "*.nfo",
        "*.sfv",
        "*.diz",
    ]
    paths = [ "${config.server.media_folder}/downloads/torrent" ]
    same_paths = [ ]
    add_limit_size = 128_000_000
    add_limit_percent = 5
    store_path = "${config.server.media_folder}/downloads/torrent/{torrent_name}"
    skip_store_metadata = false
    cache_touched_files = false
    # rw_file_cache_chown = "1000:1000"
    rw_file_cache_ttl = 86400
    rw_file_cache_path = "${config.server.media_folder}/cache"
    # WARNING: setting fast_resume to true can cause errors and problems.
    fast_resume = true
    ignore_file_patterns = [ ]
    ignore_directory_patterns = [ ]

    [clients]

    [clients.rtorrent]
    display_name = "rtorrent"
    client_type = "rtorrent"
    url = "scgi:///run/rtorrent/rpc.sock"
    session_path = "/var/lib/rtorrent/session"
    label = "cross"
  '';
  autotorrent2Package = pkgs.callPackage ./autotorrent2.nix { };
  prunerrPackage = pkgs.callPackage ./prunerr.nix { };
  autobrrPackage = pkgs.autobrr;
  autobrrFreeSpace = pkgs.writeShellScriptBin "autobrr-free-space" ''
    #!/bin/sh
    set -e

    # argument 1: torrent payload size; bytes.
    if ! [[ "$1" =~ ^[0-9]*$ ]]; then
      exit 5 # invalid 'size' argument.
    fi
    if [[ $(($1)) -gt 0 ]]; then
      if [[ $1 -gt 102400 ]]; then
        size=$(($1/1024))
      else # if the size is too small it may not be for the payload.
        size=$((5*1024*1024)) # use larger size.
      fi
    else
      size=0 # ignore torrent size.
    fi

    # argument 2: space to keep free; GiB, integer.
    if ! [[ "$2" =~ ^[0-9]*$ ]]; then
      exit 4 # invalid 'keep' argument.
    fi
    if [[ $(($2)) -gt 0 ]]; then
      keep=$2
    else
      keep=100 # default, change as needed.
    fi

    # argument 3: torrent save path.
    if [[ -z "$3" ]]; then
      path=${config.server.media_folder} # default, change as needed.
    else
      path=$3
    fi
    if ! [[ -d "$path" ]]; then
      exit 3 # invalid 'path' argument.
    fi

    # get free space available.
    have=$((`${pkgs.busybox}/bin/df "$path" | ${pkgs.busybox}/bin/awk 'END{print $4}'`))

    # get minimum free space required.
    need=$((($keep*1024*1024)+$size))

    # check if the needed free space is available.
    if [[ $have -eq 0 ]]; then
      exit 2 # no free space.
    elif [[ $have -lt $need ]]; then
      exit 1 # not enough free space.
    else
      exit 0 # free space available.
    fi
  '';
in
{
  users.groups."rtorrent" = { };
  users.users."rtorrent" = {
    isSystemUser = lib.mkForce false;
    isNormalUser = lib.mkForce true;
    group = "media";
    extraGroups = [ "rtorrent" ];
  };

  environment.systemPackages = [
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.flood
    pkgs.unpackerr
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.recyclarr
    pkgs.cross-seed
    pkgs.unrar
    autotorrent2Package
    prunerrPackage
  ]; # broken dependencies: pkgs.torrenttools pkgs.mktorrent

  systemd.tmpfiles.rules = [
    "d ${config.server.media_folder}/downloads 0770 rtorrent media"
    "d ${config.server.media_folder}/downloads/torrent 0770 rtorrent media"
    "d /var/lib/autobrr 0755 rtorrent rtorrent"
    "d /var/lib/autobrr/watch 0775 rtorrent rtorrent"
    "d /var/lib/cross-seed 0755 rtorrent rtorrent"
    "d /var/lib/cross-seed/watch 0775 rtorrent rtorrent"
    "d /var/lib/rtorrent/at2-queue 0775 rtorrent rtorrent"
    "d /var/log/rtorrent 0770 rtorrent root"
  ];
  services.rtorrent = {
    enable = true;
    user = "rtorrent";
    group = "media";
    dataPermissions = "0775";
    downloadDir = "${config.server.media_folder}/downloads/torrent";
    configText = ''
      dht.mode.set = auto
      protocol.pex.set = yes

      trackers.use_udp.set = yes

      system.umask.set = 0002

      pieces.hash.on_completion.set = no

      ## The following line can be added to .rtorrent.rc to set up watch directories
      ##
      ## Replace:
      ##     [WATCH_DIR] with the directory to watch for torrent files
      ##     [DOWNLOAD_DIR] with the directory to save the files into
      ##     [LABEL] with a label to apply to torrents added via this watch dir
      ##        Important: Thus far i have not worked out how to use spaces in label names
      ##                   Do not include spaces for .torrent files will not be imported into rtorrent if you do
      ##
      ## Remove:
      ##     d.set_custom1=[LABEL] - to not add a label to the torrent
      ##     d.delete_tied= - to not delete the .torrent file after it has been added to rtorrent
      ##
      ## Notes:
      ##     When adding multiple watch directories ensure,
      ##     the string before the 1st comma is unique for all entries (watch_directory in example)
      ##     the number after the 1st comman is unique for all entries (1 in example)

      schedule2 = watch_directory,1,30,"load.start_verbose=/var/lib/rtorrent/watch/*.torrent,d.directory.set=${config.server.media_folder}/downloads/torrent/,d.delete_tied="
      ## set added time
      method.set_key = event.download.inserted_new, loaded_time, "d.custom.set=addtime,$cat=$system.time=;d.save_full_session="

      # enable flood
      method.redirect=load.throw,load.normal
      method.redirect=load.start_throw,load.start
      method.insert=d.down.sequential,value|const,0
      method.insert=d.down.sequential.set,value|const,0

      ## automatically execute cross-seed search on finished downloads
      method.set_key=event.download.finished,cross_seed,"execute2={${cross-seedHook}/bin/cross-seed-hook,$d.hash=}"

      # Network limits
      network.http.max_open.set = 50
      network.max_open_files.set = 600
      network.max_open_sockets.set = 100

      # Peer settings
      throttle.min_peers.normal.set = 39
      throttle.max_peers.normal.set = 40
      throttle.min_peers.seed.set = -1
      throttle.max_peers.seed.set = -1
      throttle.max_downloads.global.set = 100
      throttle.max_uploads.global.set = 100
      throttle.max_downloads.set = 20
      throttle.max_uploads.set = 20
      trackers.numwant.set = 40
      ### performance
      network.receive_buffer.size.set =  16M
      network.send_buffer.size.set    = 16M

      # Miscellaneous settings
      pieces.memory.max.set = 2048M
      schedule2 = session_save, 3600, 3600, ((session.save))
      system.file.allocate.set = 0
      pieces.preload.type.set = 2
      network.xmlrpc.size_limit.set = 10M

      log.open_file = "debug_log", (cat,/var/log/rtorrent/debug_log.txt.,(system.time),.,(system.pid))
      log.add_output = "error", "debug_log"
      #log.add_output = "info", "debug_log"
      #log.add_output = "debug", "debug_log"
      #log.add_output = "tracker_debug", "debug_log"
    '';
  };

  systemd.services."natpmp-proton" = {
    enable = true;
    description = "Acquire incoming port from protonvpn natpmp";
    requires = [ "protonvpn.service" ];
    after = [ "protonvpn.service" ];
    bindsTo = [ "protonvpn.service" ];
    serviceConfig = {
      TimeoutSec = 60;
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      # [TODO: not hardcoded gateway]
      ExecStartPre = pkgs.writers.writeBash "acquire-port-vpn" ''
        echo "getting udp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .* to local port ([0-9]+) .*/UDPPORTPUBLIC=\1\nUDPPORTPRIVATE=\2/' > /run/proton_incoming"
        echo "getting tcp"
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .* to local port ([0-9]+) .*/TCPPORTPUBLIC=\1\nTCPPORTPRIVATE=\2/' >> /run/proton_incoming" && chown rtorrent:rtorrent /run/proton_incoming
      '';
      ExecStart = pkgs.writers.writeBash "keep-port-vpn" ''
        echo "looping to keep"
         while true ; do
           ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 && ${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 tcp 60
           sleep 45
         done
      '';
      Type = "simple";
      Restart = "always";
    };
  };

  systemd.services."natpmp-forward" = {
    enable = true;
    description = "Port forward natpmp open port so that public port matches private port";
    requires = [ "natpmp-proton.service" ];
    after = [ "natpmp-proton.service" ];
    bindsTo = [ "natpmp-proton.service" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      User = "root";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = pkgs.writers.writeBash "forward-port-vpn-tcp" ''
        echo "forwarding TCP $TCPPORTPRIVATE to $TCPPORTPUBLIC and UDP $UDPPORTPRIVATE to $UDPPORTPUBLIC"
        ${pkgs.nftables}/bin/nft add table ip nat
        ${pkgs.nftables}/bin/nft -- add chain ip nat prerouting { type nat hook prerouting priority -100 \; }
        ${pkgs.nftables}/bin/nft add rule ip nat prerouting tcp dport $TCPPORTPRIVATE redirect to :$TCPPORTPUBLIC
        ${pkgs.nftables}/bin/nft add rule ip nat prerouting udp dport $UDPPORTPRIVATE redirect to :$UDPPORTPUBLIC
      '';
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
  };

  systemd.services.rtorrent =
    let
      configFile = pkgs.writeText "rtorrent.rc" config.services.rtorrent.configText;
    in
    {
      bindsTo = [ "netns-vpn.service" ];
      requires = [
        "network-online.target"
        "protonvpn.service"
        "natpmp-proton.service"
        "natpmp-forward.service"
      ];
      after = [
        "protonvpn.service"
        "natpmp-proton.service"
        "natpmp-forward.service"
        "nss-lookup.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = "/run/proton_incoming";
        NetworkNamespacePath = "/var/run/netns/vpn";
        ExecStart = lib.mkForce (
          pkgs.writers.writeBash "start-rtorrent" ''
            echo "${config.services.rtorrent.package}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$TCPPORTPUBLIC -o dht.port.set=$UDPPORTPUBLIC"
            ${config.services.rtorrent.package}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$((TCPPORTPUBLIC+1)) -o dht.port.set=$UDPPORTPUBLIC
          ''
        );
      };
    };

  services.rutorrent = {
    enable = false;
    group = "rtorrent";
    hostName = "0.0.0.0";
    nginx.enable = true;
  };

  systemd.services.flood = {
    enable = true;
    description = "Flood frontend for rtorrent";
    bindsTo = [ "rtorrent.service" ];
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.flood}/bin/flood --rtsocket /run/rtorrent/rpc.sock --port 5678 --host 0.0.0.0 --baseuri /flood";
      Restart = "on-failure";
      Type = "simple";
      User = "rtorrent";
      Group = "rtorrent";
    };
  };
  networking.firewall.allowedTCPPorts = [
    5678
    5656
  ];

  users.groups."unpackerr" = { };
  users.users."unpackerr" = {
    isSystemUser = true;
    group = "unpackerr";
    extraGroups = [
      "rtorrent"
      "media"
    ];
  };

  age.secrets.unpackerrConfig = {
    file = ../secrets/unpackerrConfig.age;
    owner = "unpackerr";
    group = "unpackerr";
  };

  systemd.services.unpackerr = {
    enable = false;
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "unpackerr";
      Group = "media";
      ExecStart = "${pkgs.unpackerr}/bin/unpackerr --config=${config.age.secrets.unpackerrConfig.path}";
      Type = "simple";
    };
  };

  age.secrets."autobrrConfig" = {
    file = ../secrets/autobrrConfig.age;
    owner = "rtorrent";
    group = "rtorrent";
    path = "/var/lib/autobrr/config.toml";
  };

  systemd.services.autobrr = {
    after = [
      "flood.service"
      "network.target"
      "rtorrent.service"
    ];
    requires = [
      "flood.service"
      "rtorrent.service"
      "autotorrent2.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "rtorrent";
      Group = "media";
      WorkingDirectory = "/var/lib/autobrr";
      ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/rm -f /var/lib/autobrr/freespace.sh; ${pkgs.coreutils}/bin/cp ${autobrrFreeSpace}/bin/autobrr-free-space /var/lib/autobrr/freespace.sh'";
      ExecStart = "${autobrrPackage}/bin/autobrr --config=/var/lib/autobrr";
      Type = "simple";
    };
  };

  age.secrets.cross-seed = {
    file = ../secrets/cross-seed.age;
    owner = "rtorrent";
    group = "rtorrent";
  };
  systemd.services.cross-seed =
    let
      search-cadence = "2w";
      rss-cadence = "30min";
      delay = "60";
      snatch-timeout = "5min";
      search-timeout = "5min";
      torrent-dir = "/var/lib/rtorrent/session";
      output-dir = "/var/lib/rtorrent/at2-queue";
      fuzzy-thr = "0.1";
    in
    {
      after = [ "rtorrent.service" ];
      requires = [ "rtorrent.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "rtorrent";
        Group = "rtorrent";
        EnvironmentFile = "${config.age.secrets.cross-seed.path}";
        WorkingDirectory = "/var/lib/cross-seed";
        NetworkNamespacePath = "/var/run/netns/vpn";
        ExecStart = "${pkgs.cross-seed}/bin/cross-seed daemon --torznab $trackers --exclude-older '720 days' --exclude-recent-search '90 days' --rss-cadence ${rss-cadence} --delay ${delay} --snatch-timeout ${snatch-timeout} --search-timeout ${search-timeout} --torrent-dir ${torrent-dir} --output-dir ${output-dir} --include-single-episodes --include-non-videos --action save --match-mode partial --verbose --fuzzy-size-threshold ${fuzzy-thr} --api-key $apikey";
        Restart = "always";
      };
    };

  #  systemd.timers.autotorrent2 = {
  #    wantedBy = [ "timers.target" ];
  #    timerConfig = {
  #      OnBootSec = "5m";
  #      OnUnitActiveSec = "5m";
  #      Unit = "autotorrent2.service";
  #    };
  #  };
  systemd.services.autotorrent2 = {
    requires = [
      "rtorrent.service"
      "rtorrent.service"
    ];
    after = [
      "rtorrent.service"
      "rtorrent.service"
    ];
    wantedBy = [ "multi-user.target" ];
    script =
      let
        at2AddScript = pkgs.writeShellScriptBin "at2-add-script" ''
          #!/bin/sh
          mkdir /var/lib/rtorrent/at2-queue/processed
          ${pkgs.inotify-tools}/bin/inotifywait --monitor --event create,moved_to,modify /var/lib/rtorrent/at2-queue \
          | while read changed; do
            ${autotorrent2Package}/bin/at2 --config ${autotorrent2Config} add rtorrent /var/lib/rtorrent/at2-queue/*.torrent
            ${autotorrent2Package}/bin/at2 --config ${autotorrent2Config} scan
            ${autotorrent2Package}/bin/at2 --config ${autotorrent2Config} add rtorrent /var/lib/rtorrent/at2-queue/*.torrent
            mv /var/lib/rtorrent/at2-queue/*.torrent /var/lib/rtorrent/at2-queue/processed
            #for file in /var/lib/rtorrent/at2-queue/*.torrent; do
            #  ${autotorrent2Package}/bin/at2 --config ${autotorrent2Config} add rtorrent "$file"
            #  mv "$file" /var/lib/rtorrent/at2-queue/processed
            #done
          done
        '';
      in
      "${at2AddScript}/bin/at2-add-script";
    serviceConfig = {
      User = "rtorrent";
      Group = "rtorrent";
      Type = "simple";
      Restart = "always";
    };
  };
}
