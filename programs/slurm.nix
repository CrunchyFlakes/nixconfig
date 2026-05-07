{ pkgs, config, ... }:
{
  age.secrets.mungeKey = {
    file = ../secrets/mungeKey.age;
    owner = "munge";
    mode = "0400";
  };

  services.munge.password = config.age.secrets.mungeKey.path;

  services.slurm = {
    server.enable = true; # slurmctld
    client.enable = true; # slurmd
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
      AccountingStorageType=accounting_storage/none
    '';
    extraCgroupConfig = ''
      CgroupPlugin=disabled
    '';
    extraConfigPaths = [
      (pkgs.writeTextDir "gres.conf" ''
        Name=gpu Type=nvidia File=/dev/nvidia0
      '')
    ];

    # Keep node from staying drained after reboot
  };

  systemd.services.slurm-resume = {
    description = "Resume slurm node after slurmd starts";
    wantedBy = [ "multi-user.target" ];
    after = [ "slurmd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.slurm}/bin/scontrol update node=jmtoepperwienpc State=RESUME Reason=\"boot\"";
      RemainAfterExit = true;
    };
  };
}
