{ config, pkgs, lib, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        serverAliveInterval = 30;
        serverAliveCountMax = 5;
        compression = true;
        addKeysToAgent = "30m";
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "10h";
      };
      workCluster = {
        match = "originalhost luis-cluster*,work*,kisski-cluster* exec \"bash -c '! nc -zw1 %h 22'\"";
        proxyJump = "work-jump";
      };
      pc2Cluster = {
        match = "originalhost n2-jumphost exec \"bash -c '! nc -zw1 %h 22'\"";
        proxyJump = "workpc";
      };
      homepc = {
        user = "mtoepperwien";
        hostname = "192.168.1.149";
        proxyJump = "server";
        forwardAgent = true;
        remoteForwards = [
          {
            bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
          }
        ];
      };
      server = {
        hostname = "mosihome.duckdns.org";
        user = "mtoepperwien";
        forwardAgent = true;
      };
      tobiserver = {
        hostname = "accounts.fritz-schubert-akademie.de";
      };
      luis-cluster = {
        hostname = "login.cluster.uni-hannover.de";
        user = "nhwptoem";
      };
      luis-cluster-transfer = {
        hostname = "transfer.cluster.uni-hannover.de";
        user = "nhwptoem";
      };
      work-jump = {
        hostname = "ssh1.ai.uni-hannover.de";
        user = "toepperwien";
      };
      workpc = {
        hostname = "jmtoepperwienpc.ai.uni-hannover.de";
        user = "mtoepperwien";
        forwardAgent = true;
        remoteForwards = [
          {
            bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
          }
        ];
      };
      workpc-bootup = {
        hostname = "jmtoepperwienpc.ai.uni-hannover.de";
        user = "root";
        extraOptions."HostKeyAlias" = "workpc-bootup";
      };
      n2-jumphost = {
        hostname = "fe.noctua2.pc2.uni-paderborn.de";
        user = "inxml20";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };
      n2login1 = {
        hostname = "n2login1.ab2021.pc2.uni-paderborn.de";
        user = "inxml20";
        proxyJump = "n2-jumphost";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };
      n2login2 = {
        hostname = "n2login2.ab2021.pc2.uni-paderborn.de";
        user = "inxml20";
        proxyJump = "n2-jumphost";
        identityFile = "~/.config/ssh/yubikey.pub";
        identitiesOnly = true;
      };
      kisski-cluster = {
        hostname = "kisski01.cluster.uni-hannover.de";
        user = "mtoepper";
      };
    };
  };
}