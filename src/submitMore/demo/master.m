% master script:
% calls
%  prepareData
%  batchProcessData
%  gatherResults
matlabRelease = version('-release');
if str2double(matlabRelease(1:end-1))<2013
   disp(['Needs at least matlab R2013. Current version is ' matlabRelease '. Quitting.'])
   return
end
clean()% clean up old data

scriptNames = {'prepareData', 'batchProcessData', 'gatherResults'};
nJobs = [1 10 1];
submitCommand = {'submit', 'submit', 'submit_long'};
[jobIDs, cmd, cmdOut] = submitMore(scriptNames, nJobs,submitCommand);
system('qstat')