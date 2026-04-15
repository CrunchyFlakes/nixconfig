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
      "jmtoepperwienpc CPUs=32 Gres=gpu:nvidia:1 State=UNKNOWN"
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
  };
}
