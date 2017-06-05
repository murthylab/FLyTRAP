function prepareData()
% pre-process some data and save into DAT/
for ii = 1:10
   save(['dat/data_' int2str(ii)],'ii');
end
tic
pause(30)% wait for data to sync from node to head
toc