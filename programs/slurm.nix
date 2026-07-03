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

  systemd.services.slurm-resume = let
    resumeScript = pkgs.writeShellScript "slurm-resume" ''
      set -u
      # Wait briefly for slurmctld to accept commands, in case it just started.
      for _ in $(seq 1 10); do
        ${pkgs.slurm}/bin/scontrol ping >/dev/null 2>&1 && break
        ${pkgs.coreutils}/bin/sleep 1
      done

      state=$(${pkgs.slurm}/bin/scontrol -i show node jmtoepperwienpc 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -oP 'State=\K\S+' | ${pkgs.coreutils}/bin/head -n1 || true)

      case "$state" in
        DOWN|DRAIN|DRAINING|FAIL|NOT_RESPONDING|UNKNOWN)
          ${pkgs.slurm}/bin/scontrol update NodeName=jmtoepperwienpc State=RESUME Reason=boot
          ;;
        *)
          echo "slurm-resume: node state is '$state', skipping RESUME"
          exit 0
          ;;
      esac
    '';
  in {
    description = "Resume slurm node after slurmd starts";
    wantedBy = [ "multi-user.target" ];
    after = [ "slurmctld.service" ];
    serviceConfig = {
      Type = "oneshot";
      Environment = "SLURM_CONF=${config.services.slurm.etcSlurm}/slurm.conf";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = resumeScript;
      RemainAfterExit = true;
    };
  };
}
