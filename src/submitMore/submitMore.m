function [jobIDs, cmd, cmdOut] = submitMore(scriptNames, nJobs, varargin)
% [jobIDs, cmd, cmdOut] = submitMore(scriptNames, nJobs, [submitCommand='submit'])

% scriptNames  - cell array of string, WITHOUT '.m' appended
% nJobs        - number of jobs for each script, array same size as
%                scriptNames or size 1
% submitCmd    - string, either 'submit', 'submit_short', 'submit_long',
%                'submit_verylong', cell array same size as scriptNames or size 1

[SLURM, QSUB] = getClusterType();
assertWarn(SLURM | QSUB, 'No compatible cluster manager found.');

if SLURM % prefer SLURM over QSUB, even if QSUB is available
   [jobIDs, cmd, cmdOut] = submitMoreSLURM(scriptNames, nJobs, varargin);
elseif QSUB
   [jobIDs, cmd, cmdOut] = submitMoreQSUB(scriptNames, nJobs, varargin);
end
