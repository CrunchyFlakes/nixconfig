# Slurm on jmtoepperwienpc

Single-node Slurm cluster for local job scheduling on the work PC.

## Setup

Both `slurmctld` (controller) and `slurmd` (node daemon) run on the same machine.
Munge authentication is auto-enabled by the NixOS module.

- 32 CPU cores
- 1 NVIDIA GPU via GRES
- Accounting via slurmdbd + MariaDB (slurm_acct_db)
- Cgroups disabled to avoid conflicts

## Usage

```bash
sinfo                              # check node/partition status
squeue                             # list running jobs
srun --ntasks=4 my-command         # run a job interactively
srun --ntasks=1 --gres=gpu:1 ...   # run a GPU job
sbatch job.sh                      # submit a batch job
```

## Notes

- Munge key is auto-generated on first boot at `/etc/munge/munge.key`
- To add more nodes: extend `nodeName` and `partitionName` in `slurm.nix`
- To reset accounting state: `sudo rm -rf /var/spool/slurmctld/clustername && sudo systemctl restart slurmdbd slurmctld`
- To re-enable cgroups for resource isolation: remove `CgroupPlugin=disabled`
