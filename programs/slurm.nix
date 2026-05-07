{ pkgs, config, ... }:
{
  age.secrets.mungeKey = {
    file = ../secrets/mungeKey.age;
    owner = "munge";
    mode = "0400";
  };

  services.munge.password = config.age.secrets.mungeKey.path;

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "slurm_acct_db" ];
    ensureUsers = [
      {
        name = "slurm";
        ensurePermissions = {
          "slurm_acct_db.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.slurm = {
    server.enable = true; # slurmctld
    client.enable = true; # slurmd
    dbdserver.enable = true;
    clusterName = "workpc";
    controlMachine = "jmtoepperwienpc";
    nodeName = [
      "jmtoepperwienpc CPUs=14 Sockets=1 CoresPerSocket=7 ThreadsPerCore=2 RealMemory=64068 Gres=gpu:nvidia:1 State=UNKNOWN"
    ];
    partitionName = [
      "main Nodes=jmtoepperwienpc Default=YES MaxTime=INFINITE State=UP"
    ];
    extraConfig = ''
      GresTypes=gpu
      AccountingStorageType=accounting_storage/slurmdbd
      JobAcctGatherType=jobacct_gather/linux
      JobAcctGatherFrequency=30
    '';
    extraCgroupConfig = ''
      CgroupPlugin=disabled
    '';
    extraConfigPaths = [
      (pkgs.writeTextDir "gres.conf" ''
        Name=gpu Type=nvidia File=/dev/nvidia0
      '')
    ];
  };

  systemd.services.slurmctld = {
    after = [ "slurmdbd.service" ];
    wants = [ "slurmdbd.service" ];
  };

  systemd.services.slurm-resume = {
    description = "Resume slurm node after slurmd starts";
    wantedBy = [ "multi-user.target" ];
    after = [ "slurmctld.service" ];
    serviceConfig = {
      Type = "oneshot";
      Environment = "SLURM_CONF=${config.services.slurm.etcSlurm}/slurm.conf";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = ''
        ${pkgs.slurm}/bin/scontrol update NodeName=jmtoepperwienpc State=RESUME Reason="boot"
      '';
      RemainAfterExit = true;
    };
  };
}
