{ config, lib, pkgs, inputs, agenix, ... }:
let
  rtorrentPackage = pkgs.callPackage ./rtorrent/default.nix { libtorrent = pkgs.callPackage ./rtorrent/libtorrent.nix {}; };
  autobrrPackage = pkgs.callPackage ./autobrr.nix {};
  autobrrFreeSpace = pkgs.writeBash "autobrr-free-space" ''
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
      path="/torrents" # default, change as needed.
    else
      path=$3
    fi
    if ! [[ -d "$path" ]]; then
      exit 3 # invalid 'path' argument.
    fi
    
    # get free space available.
    have=$((`df "$path" | awk 'END{print $4}'`))
    
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
in {
  users.groups."rtorrent" = {};
  users.users."rtorrent" = {
    isSystemUser = true;
    group = "usenet";
    extraGroups= [ "rtorrent" ];
  };

  environment.systemPackages = [ inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.flood pkgs.unpackerr ];

  services.rtorrent = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.jesec-rtorrent;
    user = "rtorrent";
    group = "usenet";
    dataPermissions = "0775";
    downloadDir = "/mnt/kodi_lib/downloads_torrent";
    configText = ''
      dht.mode.set = auto
      protocol.pex.set = yes

      trackers.use_udp.set = yes

      system.umask.set = 0002
    '';
  };

  systemd.services."natpmp-proton" = {
    enable = true;
    description = "Acquire incoming port from protonvpn natpmp";
    requires = [ "protonvpn.service" ];
    after = [ "protonvpn.service" ];
    bindsTo = [ "protonvpn.service" ];
    serviceConfig = {
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
    };
  };

  systemd.services.rtorrent = let
    configFile = pkgs.writeText "rtorrent.rc" config.services.rtorrent.configText;
    rtorrentPackage = config.services.rtorrent.package;
  in {
    bindsTo = [ "netns@vpn.service" ];
    requires = [ "network-online.target" "protonvpn.service" "natpmp-proton.service" "natpmp-forward.service" ];
    after = [ "protonvpn.service" "natpmp-proton.service" "natpmp-forward.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = lib.mkForce (pkgs.writers.writeBash "start-rtorrent" ''
        echo "${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$TCPPORTPUBLIC -o dht.port.set=$UDPPORTPUBLIC
"
        ${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$TCPPORTPUBLIC -o dht.port.set=$UDPPORTPUBLIC
      '');
    };
  };

  systemd.services.flood = {
    enable = true;
    description = "Flood frontend for rtorrent";
    bindsTo = [ "rtorrent.service" ];
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.flood}/bin/flood --rtsocket /run/rtorrent/rpc.sock --port 5678 --host 0.0.0.0";
      Restart = "on-failure";
      Type = "simple";
      User = "rtorrent";
      Group = "rtorrent";
    };
  };
  networking.firewall.allowedTCPPorts = [ 5678 5656 ];

  users.groups."unpackerr" = {};
  users.users."unpackerr" = {
    isSystemUser = true;
    group = "unpackerr";
    extraGroups = [ "rtorrent" "usenet" ];
  };

  age.secrets.unpackerrConfig = {
    file = ../secrets/unpackerrConfig.age;
    owner = "unpackerr";
    group = "unpackerr";
  };

  systemd.services.unpackerr = {
    after = [ "rtorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "unpackerr";
      Group = "usenet";
      ExecStart = "${pkgs.unpackerr}/bin/unpackerr --config=${config.age.secrets.unpackerrConfig.path}";
      Type = "simple";
    };
  };


  users.groups."autobrr" = {};
  users.users."autobrr" = {
    isSystemUser = true;
    group = "autobrr";
    extraGroups = [ "rtorrent" "usenet" ];
  };

  systemd.tmpfiles.rules = [ "d /var/lib/autobrr 0750 autobrr autobrr" ];
  age.secrets."autobrrConfig" = {
    file = ../secrets/autobrrConfig.age;
    owner = "autobrr";
    group = "autobrr";
    path = "/var/lib/autobrr/config.toml";
  };

  systemd.services.autobrr = {
    after = [ "flood.service" ];
    requires = [ "flood.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "autobrr";
      Group = "usenet";
      WorkingDirectory = "/var/lib/autobrr";
      ExecStartPre = "cp ${autobrrFreeSpace} /var/lib/autobrr/freespace.sh";
      ExecStart = "${autobrrPackage}/bin/autobrr --config=/var/lib/autobrr";
      Type = "simple";
    };
  };
}
