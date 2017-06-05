function [SLURM, QSUB] = getClusterType()

[ret, ~] = unix('sbatch --help');% `~` to silence output
if ret==0
   SLURM = 1;
else
   SLURM = 0;
end

[ret, ~] = unix('qstat');% `~` to silence output
if ret==0
   QSUB = 1;
else
   QSUB = 0;
end
