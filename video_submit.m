function video_submit(varargin)
%  video_submit('TRACK'/'POSTPROCESS'= [1 0],[mode], [path])
% does not run post-processing as default

if nargin==0
   varargin{1} = [1 1 1];
end
inParser = inputParser;
addRequired(inParser,'tasks', @(x) isnumeric(x) && length(x)==3);
addParamValue(inParser, 'path', fullfile('dat', '**','*_init.mat'), @ischar);%#ok<*NVREPL> % should be addParameter - used the old name for compatibility with 2013a
addParamValue(inParser, 'mode', 'auto', @(x) any(validatestring(x, {'local', 'cluster','auto'})));% should be addParameter - used the old name for compatibility with 2013a
parse(inParser,varargin{:});
disp(inParser.Results)

switch inParser.Results.mode
   case {'auto'}
      CLUSTER =  isunix && ~ismac; % RONDO (unix)
      LOCAL = ispc || ismac;% MAC or PC
   case {'local'}
      CLUSTER = false; LOCAL = true;
   case {'cluster'}
      CLUSTER = true; LOCAL = false;
   otherwise
      warning('unknown MODE - defaulting to local')
      CLUSTER = false; LOCAL = true;
end

[SLURM, QSUB] = getClusterType();
if CLUSTER
   assert(QSUB || SLURM, 'Cluster job requested but neither QSUB nor SLURM are available.');
end

tasks = logical(inParser.Results.tasks);

COURTSHIP   = ~isempty(strfind(cd,'courtship'));
LONGCHAMBER = ~isempty(strfind(cd,'longchamber'));
PLAYBACK    = ~isempty(strfind(cd,'playback'));
MIC4        = ~isempty(strfind(cd,'4mic'));

if PLAYBACK
   maxChambersPerFile = 12;
else
   maxChambersPerFile = 1; % default for COURTSHIP and LONGCHAMBER
end

%%
% naively, this will submit 2x24 jobs per folder (one for each init file) -
% so we submit only unique folders
% extract dirNames
fileNames = getFileNames(inParser.Results.path);
for fil = 1:length(fileNames)
   dirNames{fil} = fileparts(fileNames{fil});
end
% only keep unique dirs
[~, uniIdx] = unique(dirNames);
fileNames = fileNames(uniIdx);

%%
for fil = length(fileNames):-1:1
   disp(fileNames{fil})
   try
      oldDir = pwd;
      fileDir = fileparts(fileNames{fil});
      cd(fileDir) % need to `cd` here - otherwise sbatch will complain
      
      fileList = dir('*_init.mat');% submit N jobs per INIT file in the folder
      nJobs = [1 maxChambersPerFile*length({fileList.name}) 1];
      
      scriptNames = {'video_preProcess', 'video_tracker', 'video_postProcess'};
      if QSUB
         submitCommands = {'submit_short', 'submit_long', 'submit_short'};
      elseif SLURM
         submitCommands = {'sbatch --time=1:00:00', 'sbatch --time=24:00:00', 'sbatch --time=1:00:00'};
      end
      
      if LOCAL % run locally
         for ppp = 1:length(tasks)
            if tasks(ppp)
               try
                  eval(scriptNames{ppp})
               catch ME
                  disp(ME.getReport());
               end
            end
         end
      elseif CLUSTER % submit to cluster if requested
         for ppp = 1:length(tasks)
            if tasks(ppp)
               % copy necessary scripts (as indicated by tasks) to the data folder
               try
                  if isunix
                     unix(['cp -vf ' which([scriptNames{ppp} '.m']) ' .']);
                  else
                     copyfile(which([scriptNames{ppp} '.m']), '.', 'f');
                  end
               end
            end
         end
         [jobIDs, cmd, cmdOut] = submitMore(scriptNames( tasks ), nJobs( tasks ), submitCommands( tasks ));
      end
      
      cd(oldDir)
   catch ME
      disp(ME.getReport)
      cd(oldDir)
   end
end

