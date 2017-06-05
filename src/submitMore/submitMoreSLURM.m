function [jobIDs, cmd, cmdOut] = submitMoreSLURM(scriptNames, nJobs, varargin)
% [jobIDs, cmd, cmdOut] = submitMore(scriptNames, nJobs, [submitCommand='submit'])

% scriptNames  - cell array of string, WITHOUT '.m' appended
% nJobs        - number of jobs for each script, array same size as
%                scriptNames or size 1
% submitCmd    - string, either 'submit', 'submit_short', 'submit_long',
%                'submit_verylong', cell array same size as scriptNames or size 1

nScripts = length(scriptNames);

if isempty(varargin) || isempty(varargin{1})
   submitCommand(1:nScripts) = {'sbatch --time=24:00:00'};
else
   if length(varargin)==1 && ~iscell(varargin{1})
      submitCommand(1:nScripts) = varargin(1);
   else
      submitCommand = [varargin{1}{:}];
   end
end
if length(nJobs)==1
   nJobs(1:nScripts) = nJobs;
end

%% submit all scripts
disp(['RUNNING ' int2str(nScripts) ' scripts.'])
for scr = 1:nScripts
   % write command to script file
   scriptFileName = [tempname('./') '.slurm'];
   fid = fopen(scriptFileName,'wt');
   fprintf(fid, '%s\nmatlab -r ''%s''', '#!/bin/bash', scriptNames{scr});
   fclose(fid);
   %
   if scr==1
      cmd{scr} = [submitCommand{scr} ' --array=1-' int2str(nJobs(scr)) ' ' scriptFileName];
   else
      cmd{scr} = [submitCommand{scr} ' --dependency=afterany:' jobIDs{scr-1} ' --array=1-' int2str(nJobs(scr)) ' ' scriptFileName];
   end
%    disp(['submitting script #' int2str(scr) ' :'])
%    disp(['   ' cmd{scr}])
   [status, cmdOut{scr}] = system(cmd{scr});
   if status~=0
      disp(['   script #' int2str(scr) ' returned with error:'])
      disp(['   ' cmdOut{scr}])
      break;
   else
      disp(['   ' cmdOut{scr}])
      jobIDs{scr} = getJobID(cmdOut{scr});
%       disp(['   script #' int2str(scr) ' returned JOBID: ' jobIDs{scr}])
   end
end
