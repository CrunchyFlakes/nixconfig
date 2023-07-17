{ config, lib, pkgs, agenix, ... }:

let
  libtorrent = pkgs.callPackage ./libtorrent.nix {};
  rtorrent = pkgs.callPackage ./rtorrent.nix { libtorrent = libtorrent; };
in {
  users.groups."transmission" = {};
  users.users."transmission" = {
    isSystemUser = true;
    group = "usenet";
    extraGroups= [ "rtorrent" ];
  };

  environment.systemPackages = [ pkgs.flood pkgs.unpackerr ];

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    user = "transmission";
    group = "usenet";
    settings.umask = 2;
    settings.rpc-bind-address = "unix:/run/transmission/transmission.sock";
    settings.download-dir = "/mnt/kodi_lib/tmp";
    settings."rpc-host-whitelist" = "localhost,pi4.home.lan";
    openRPCPort = true;
  };

#  services.rtorrent = {
#    enable = true;
#    package = pkgs.jesec-rtorrent;
#    user = "rtorrent";
#    group = "usenet";
#    dataPermissions = "0775";
#    downloadDir = "/mnt/kodi_lib/downloads_torrent";
#    configText = ''
#      dht.mode.set = auto
#      protocol.pex.set = yes
#
#      trackers.use_udp.set = yes
#
#      system.umask.set = 0002
#    '';
#  };

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
        eval "${pkgs.libnatpmp}/bin/natpmpc -g 10.2.0.1 -a 0 34828 udp 60 | ${pkgs.busybox}/bin/grep 'Mapped public port' | ${pkgs.busybox}/bin/sed -E 's/.*Mapped public port ([0-9]+) .* to local port ([0-9]+) .*/TCPPORTPUBLIC=\1\nTCPPORTPRIVATE=\2/' >> /run/proton_incoming" && chown transmission:transmission /run/proton_incoming
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
      ExecStop = pkgs.writers.writeBash "stop-forward-port-vpn-tcp" ''
        echo "stopping forwarding"
        ${pkgs.nftables}/bin/nft delete table ip nat
      '';
      Type = "oneshot";
    };
  };

#  systemd.services.rtorrent = let
#    configFile = pkgs.writeText "rtorrent.rc" config.services.rtorrent.configText;
#    rtorrentPackage = config.services.rtorrent.package;
#  in {
#    bindsTo = [ "netns@vpn.service" ];
#    requires = [ "network-online.target" "protonvpn.service" "natpmp-proton.service" "natpmp-forward.service" ];
#    after = [ "protonvpn.service" "natpmp-proton.service" "natpmp-forward.service" ];
#    wantedBy = [ "multi-user.target" ];
#    serviceConfig = {
#      EnvironmentFile = "/run/proton_incoming";
#      NetworkNamespacePath = "/var/run/netns/vpn";
#      ExecStart = lib.mkForce (pkgs.writers.writeBash "start-rtorrent" ''
#        echo "${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$TCPPORTPUBLIC -o dht.port.set=$UDPPORTPUBLIC
#"
#        ${rtorrentPackage}/bin/rtorrent -n -o system.daemon.set=true -o import=${configFile} -o network.port_range.set=$TCPPORTPUBLIC-$TCPPORTPUBLIC -o dht.port.set=$UDPPORTPUBLIC
#      '');
#    };
#  };

  systemd.services.transmission = {
    bindsTo = [ "netns@vpn.service" ];
    requires = [ "network-online.target" "protonvpn.service" "natpmp-proton.service" "natpmp-forward.service" ];
    after = [ "protonvpn.service" "natpmp-proton.service" "natpmp-forward.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = "/run/proton_incoming";
      NetworkNamespacePath = "/var/run/netns/vpn";
      ExecStart = lib.mkForce "${config.services.transmission.package}/bin/transmission-daemon -f -g ${config.services.transmission.home}/.config/transmission-daemon ${lib.escapeShellArgs config.services.transmission.extraFlags} --peerport $TCPPORTPUBLIC --no-portmap --log-level=debug --logfile /var/lib/transmission/log.txt";
    };
  };

  systemd.services.flood = {
    enable = true;
    description = "Flood frontend for rtorrent";
    bindsTo = [ "transmission.service" ];
    after = [ "transmission.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.flood}/bin/flood --trurl unix:/run/transmission/transmission.sock --host 0.0.0.0 ";
      Restart = "on-failure";
      Type = "simple";
      User = "transmission";
      Group = "transmission";
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
}
