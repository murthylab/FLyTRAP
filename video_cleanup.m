function video_cleanup(baseDir, patterns)
% remove temporary files
% USAGE
%   video_cleanup(baseDir, patterns)
% ARGS:
%  baseDir - (defaults to `dat/**`)
%  patterns - (defaults to `{'*.m.o*', '*.tif', '*.png', '*.m', '*_wip.mat', 'slurm*.out', '*.slurm'}`)
if ~exist('baseDir','var')
   baseDir = fullfile('dat','**');
end
if ~exist('patterns','var')
   patterns = {'*.m.o*', '*.tif', '*.png', '*.m', '*_wip.mat', 'slurm*.out', '*.slurm'};%, '*song_ch*.mat'}%, '*sInf.mat'}
end

for pat = 1:length(patterns)
   fileList = rdir(fullfile(baseDir, patterns{pat}));
   fprintf('deleting %d files matching %s.\n', length(fileList), patterns{pat});
   for fil = 1:length(fileList)
      delete(fileList(fil).name)
   end
end
