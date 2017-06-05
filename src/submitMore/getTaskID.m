function tid = getTaskID()
tid = nan;
if isunix && ~ismac % rondo
   tid = str2double(getenv('SGE_TASK_ID'));
   if isnan(tid) % maybe we are on DELLA
      tid = str2double(getenv('SLURM_ARRAY_TASK_ID'));
   end
elseif (~isunix && ismac) || ispc % local
   t = getCurrentTask();
   if isempty(t)
      tid = 1;
   else
      tid = t.ID;
   end
end
