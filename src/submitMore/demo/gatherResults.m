function gatherResults()
% get all results files in RES/
fileList = dir('res/results*');
fileNames = {fileList.name}'

% load each results file and gather in a single array RES
for fil = 1:length(fileNames)
   load(['res/' fileNames{fil}]);
   res(fil) = results;
end

% save gathered results
save('res/results_all', 'res')

