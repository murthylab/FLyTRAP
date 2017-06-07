cc()
addpath(genpath('src'))
tb = readtable('playback.xlsx');
playbackLists = readtable('playbackLists.xlsx');
if ismac
   resFolder = '/Volumes/murthy/jan/playback/res/';
elseif ispc
   resFolder = 'Z:\jan\playback\res\';
end
%%
stiIdx = size(playbackLists,1):-1:size(playbackLists,1)-9;
disp(playbackLists(stiIdx,:))
%%
for sti = stiIdx
   try
      %% load results
      clear rr
      clear oriG
      stimStrg = playbackLists.stimName{sti};
      disp(stimStrg)
      carrierIdx = find(strcmp(tb.stimulus, stimStrg));
      fileList = tb.date(carrierIdx);
      fileList = cellfun(@horzcat,  repmat({resFolder}, length(fileList),1), fileList, repmat({'_spd'}, length(fileList),1),'UniformOutput',false);
      rr = readFiles(fileList(1:end));
      % load meta data
      rr.newFs = 10;
      rr.stimIdx = eval(playbackLists.stimidx{sti});
      rr.baseLineIdx = eval(playbackLists.baselineidx{sti});
      rr.badRecording = eval(playbackLists.badrecording{sti});
      rr.xLabel = playbackLists.xlabel{sti};
      rr.x = num2cellstr(eval(playbackLists.xvalues{sti}));

      %%
      rr.spdF = bsxfun(@times,rr.spdF,rr.FPS./rr.PXperMM);                  % convert to mm/s
      rr.baseSpd = nanmean(rr.spdF(rr.baseLineIdx,:));                     % avg. speed during baseLineIdx
      rr.testSpd = nanmean(rr.spdF(rr.stimIdx,:));                         % avg. speed during stimIdx
      rr.diffSpd = (rr.testSpd - rr.baseSpd);%./rr.baseSpd;                % subtract baseline
      
      rr.testPosX = mean(rr.posF(rr.stimIdx, :, 1), 1);                    % get x,y position during stimulus
      rr.testPosY = mean(rr.posF(rr.stimIdx, :, 2), 1);
      
      rr.badIdx = ismember(rr.recID,rr.badRecording);                         % get rid of badRecordings
      rr.diffSpd(rr.badIdx) = nan;
      
      posDiff = diff(rr.posF, [], 1);                                      % ?? velocity vector
      [ang, rad] = cart2pol(posDiff(:,:,1), posDiff(:,:,2));               % movement direction
      ang = mapFun(@smooth, ang,5);
      ang(rad<1) = nan;
      angF = padarray(ang, [1 0], 'pre');
      rr.testAngF = nanmean(rad2deg(angF(rr.stimIdx,:)),1);
      
      %% get rid of trials for which fly is close to chamber ends
      oriG = zeros(size(rr.testAngF));
      angThres = nan;%30
      posThres = nan;%nan;%60
      
      % maybe  these should be per-fly minima - not total minima to account for diffs. in chamber position/box?
      G = rr.recID*1000 + rr.flyID;
      uniG = unique(G);
      for gg = 1:length(uniG)
         thisIdx = find(G==uniG(gg));
         if isnan(angThres) % sort by position only
            % if in LOWER part
            oriG( thisIdx(rr.testPosY(thisIdx)<min(rr.testPosY(thisIdx))+posThres)) =  1;
            % if in UPPER part
            oriG( thisIdx(rr.testPosY(thisIdx)>max(rr.testPosY(thisIdx))-posThres)) = -1;
         else % sort by angle and position
            % if in lower part and angle DOWN
            oriG( thisIdx(rr.testPosY(thisIdx)<min(rr.testPosY(thisIdx))+posThres & (rr.testAngF(thisIdx)<-angThres)) ) = -1;
            % if in lower part and angle UP
            oriG( thisIdx(rr.testPosY(thisIdx)<min(rr.testPosY(thisIdx))+posThres & (rr.testAngF(thisIdx)>angThres)) ) = 1;
            % if in UPPER part and angle DOWN
            oriG( thisIdx(rr.testPosY(thisIdx)>max(rr.testPosY(thisIdx))-posThres & (rr.testAngF(thisIdx)<-angThres)) ) = -2;
            % if in UPPER part and angle UP
            oriG( thisIdx(rr.testPosY(thisIdx)>max(rr.testPosY(thisIdx))-posThres & (rr.testAngF(thisIdx)>angThres)) ) = 2;
         end
      end
      
      %       mTrace = bsxfun(@minus, rr.spdF, rr.baseSpd);                        % baseline subtract each trace
      %       mTrace(:,rr.badIdx) = nan;
      %       nanmeanG = @(x) nanmean(x,1);
      %       [mmm2, gn2] = grpstats(mTrace', [rr.stiID; oriG]', {nanmeanG, 'gname'});
      %       gn2 = str2double(gn2);
      %
      %       for st = 1:rr.stis
      %          mySubPlot(rr.stis, 3, st, 2)
      %          plot(mapFun(@smooth, mmm2(gn2(:,1)==st,:)', 9))
      %          title(sprintf('stimulus %d', st))
      %          colorLines(limit(parula(length(unique(oriG)))-0.1))
      %          axis('tight')
      %          vline([300 340])
      %       end
      %
      %       uniPosG = unique(gn2(:,2));
      %       for st = 1:length(uniPosG)
      %          mySubPlot(length(uniPosG), 3, st, 3)
      %          plot(mapFun(@smooth, mmm2(gn2(:,2)==uniPosG(st),:)', 9))
      %          title(sprintf('ori/pos %d', st))
      %          colorLines(lines(rr.stis))
      %          axis('tight')
      %          vline([300 340])
      %       end
      %       set(gcls,'LineWidth',1)
      %
      %       fprintf('%1.0f percent of flies ware in the wrong place at the wrong time\n', 100*(1-mean(oriG==0)))
      %% run stats
      rr.badIdx = ismember(rr.recID,rr.badRecording) | oriG~=0;               % get rid of flies at chamber ends
      rr.diffSpd(rr.badIdx) = nan;
      ranks = tiedrank(rr.diffSpd);
      [pval,tab,stats] = anovan(ranks(:), [[rr.stiID]; rr.flyID+1000*rr.recID]', 'display','off','varnames',{rr.xLabel, 'fly'});
      [mcmp] = multcompare(stats,'display','on','ctype','lsd');
      
      tab{6,1} = 'N';
      tab{6,2} = sum(~rr.badIdx);
      anovaTab = cell2table(tab(2:end,2:end));
      anovaTab.Properties.VariableNames = matlab.lang.makeValidName(tab(1,2:end));
      anovaTab.Properties.RowNames = matlab.lang.makeValidName(tab(2:end,1));
      disp(anovaTab)
      
      varnames = cellfun(@horzcat,  repmat({rr.xLabel}, length(rr.x),1), rr.x,'UniformOutput',false);
      varnames = matlab.lang.makeValidName(varnames);
      pTab = triu(squareform(mcmp(:,end)));
      pTab(pTab==0) = nan;
      pTab = round(100*pTab)/100;
      try
         posthocTab = array2table(pTab, ...
            'rownames', varnames, 'variablenames', varnames);
         disp(posthocTab)
      end
      %       if mfilename()
      %          writetable(anovaTab, ['log/' stimStrg '_ANOVA.txt'], 'Delimiter','\t')
      %          writetable(posthocTab, ['log/' stimStrg '_posthoc.txt'], 'Delimiter','\t')
      %       end
      
      %% save per-chamber results plotting
      mTrace = bsxfun(@minus, rr.spdF, rr.baseSpd);                        % cleaned-up baseline subtracted rr.traces4plot
      % average by fly (recID) and stimulus (stiID)
      G = [rr.stiID; rr.recID]';
      G(rr.badIdx) = nan;
      [mmm, gn] = grpstats(mTrace', G, {@(x)nanmean(x,1), 'gname'});
      mmm = mmm';
      gn = cellfun(@str2num, gn);
      if length(unique(rr.stiID))>20
         warning('too many stimuli - will not plot')
      else
         figure(2)
         clf
         cmap = limit(jet(rr.stis)-0.2);
         for rec = 1:max(rr.recID)
            try
               mySubPlot(max(rr.recID),4,rec,1:3)
               plot(mmm(:,gn(:,2)==rec),'LineWidth',1)
               axis('tight')
               cmapline('colormap',cmap);
               hline(0)
               vline([30*rr.newFs(1) 34*rr.newFs(1)])
               mySubPlot(max(rr.recID),4,rec,4)
               plot(nanmean(mmm(rr.stimIdx,gn(:,2)==rec)), '-k')
               hold on
               gscatter(1:length(rr.x), nanmean(mmm(rr.stimIdx,gn(:,2)==rec)), 1:length(rr.x),fliplr(cmap), [], 20, 'off')
            end
         end
         
         if mfilename()
            set(gcas,'Color','none','box','off', 'TickDir', 'out')
            figexp(['fig/' stimStrg '_singleExp'],1,.2*max(rr.recID))
         end
      end
      %%
      if length(unique(rr.stiID))>20
         warning('too many stimuli - will not plot')
      else
         figure(1)
         clf
         cmap = limit(parula(rr.stis)-0.1);
         subplot(133)
         hold on
         [rr.avgDeltaSpeedPerFly, gnn] = grpstats(rr.diffSpd, [rr.stiID; rr.flyID+1000*rr.recID]', {@nanmean, 'gname'});
         rr.avgDeltaSpeedPerFly = reshape(rr.avgDeltaSpeedPerFly,[],nanmax(rr.stiID));
         [hL, hE] = myErrorBar(1:rr.stis,nanmean(rr.avgDeltaSpeedPerFly,1)', sem(rr.avgDeltaSpeedPerFly)');
         set([hL hE],'Color','k','LineWidth',2)
         gscatter(1:rr.stis, nanmean(rr.avgDeltaSpeedPerFly,1), 1:rr.stis, cmap,[],24,'off')
         set(gca, 'XTick',1:length(rr.x));
         ylabel('\Deltas [mm/s]')
         xlabel(rr.xLabel)
         
         % plot response traces
         subplot(1,3,1:2)
         G = [rr.stiID; rr.flyID+1000*rr.recID]';
         G(rr.badIdx) = nan;
         [mmm, gn] = grpstats(mTrace', G, {@(x)nanmean(x,1), 'gname'});
         [rr.traces4plot, rr.traces4plotStd, tmpN] = grpstats(mmm,gn(:,1),{@nanmean, @nanstd, @numel});                        % get avg. trace for each stim
         rr.traces4plot = mapFun(@conv,rr.traces4plot',normalizeSum(gausswin(8)));  % smooth for plotting
         rr.traces4plot = rr.traces4plot(4:end-4,:);
         rr.traces4plotStd = mapFun(@conv,rr.traces4plotStd',normalizeSum(gausswin(8)));  % smooth for plotting
         rr.traces4plotStd = rr.traces4plotStd(4:end-4,:);
         rr.traces4plotT = (1:size(rr.traces4plot,1));
         rr.traces4plotN = tmpN(:,1);
         hl = mseb(repmat(rr.traces4plotT',1,rr.stis)', rr.traces4plot', ...
            bsxfun(@times, rr.traces4plotStd', 1./sqrt(rr.traces4plotN)), ...
            struct('col', cmap),10);
         axis('tight')
         hline(0)
         vline([30*rr.newFs(1) 34*rr.newFs(1)])                               % stimulus duration
         hold on
         plot([min(rr.stimIdx) max(rr.stimIdx)], [-0.2 -0.2], 'r', 'Linewidth', 2)% time window for averaging speed
         legend(rr.x,'Location','SouthWest')
         legend('boxoff')
         ylabel('\Deltas [mm/s]')
         set(gca,'XColor','none')%, 'YLim', [-0.45 0.1])
         scalebar(500, -.2, 10*rr.newFs, '10 s',10)
         
         set(gcas,'box','off','color','none','TickDir','out')
         if mfilename()
            figexp(['fig/' stimStrg],1.5,.5)
         end
      end
      if mfilename()
         save(['res/' stimStrg], 'rr')
      end
   catch ME
      disp(ME.getReport());
   end
end
