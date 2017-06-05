function jobID =getJobID(string)
% get JOBID from 'submit' return string
% for QSUB:
% return string of the submit command is of the form
% 'SCRIPTNAME.m output will be in SCRIPTNAME.m.o4251723 ' for single jobs
% 'SCRIPTNAME.m output will be in SCRIPTNAME.m.o4251723.1-10:1 ' for array jobs
% for SLURM
% return string is of the form
% 'Submitted batch job 65899' for single and array jobs

if strfind(string, 'output will be in')
   % we first split at 'm.o' to get a string of the form 'JOBID ' or 'JOBID.1:10:1
   token = strsplit(string,'.m.o');
   % then split at '.' to get a string of trailing job information (for job arrays)
   token2 = strsplit(token{end},'.');
   jobID = token2{1};
   % finally, get rid of leading 'o' and remove any trailing whitespace (for single jobs)
   %    jobID = strtrim(token2{2}(2:end));
elseif strfind(string, 'ubmitted batch job')
   token = strsplit(string, ' ');
   jobID = token{end};
else
   warning('"%s" does not contain a known pattern', string);
end
jobID = strtrim(jobID);% remove trailing linebreaks or spaces

