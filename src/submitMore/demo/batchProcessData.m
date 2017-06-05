function batchProcessData()
% load job specific data
load(['dat/data_' int2str( getTaskID() )])
% do something silly
results = ii*2;
% save into RES/
save(['res/results_' int2str( getTaskID() )], 'results')
tic
pause(30)% wait for data to sync from node to head
toc

