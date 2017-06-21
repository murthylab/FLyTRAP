cc()
playbackLists = readtable('playbackLists.xlsx');
playbackLists = playbackLists(contains(playbackLists.stimName, 'atr'),:);
%%
for fil = 1:size(playbackLists,1)
   try
      disp(['res/' playbackLists.stimName{fil}])
      load(['res/' playbackLists.stimName{fil}])
      
      %%
      stimNames = [rr.p.ctrl.stimNames{:}]';
      ipi = cellfun(@(x)str2double(x(end-1:end)), stimNames(rr.stiID));
      [Gipi, GipiLabel] = grp2idx(ipi);
      GipiLabel = str2double(GipiLabel);
      stiID = Gipi'+rr.modID*10+10;
      %    clf
      %    subplot(211)
      %    plot(ipi)
      %    hold on
      %    plot(rr.modID*100, 'o-k')
      %    subplot(212)
      %    plot(stiID)
      %%
      cols = lines(length(GipiLabel));
      colsB = rgb2hsv(cols);
      colsB = hsv2rgb(limit(colsB + [0 -0.4 0.1]));
      cols = [cols; colsB];
      cmap = flipud(cbrewer('Div', 'RdBu', 64));
      clf
      subplot(711)
      [M, gn] = grpstats((rr.spdF-rr.baseSpd)', stiID, {@nanmean, 'gname'});
      T = (1:size(M,2))/10-30;
      gn = str2double(gn);
      imagesc(T,[],mapFun(@smooth, M',11)')
      hline(5.5,'r')
      lb = [num2cellstr(GipiLabel(1:5),2, ' OFF'); num2cellstr(GipiLabel(1:5),2, ' ON')]
      set(gca, 'YTick', 1:10, 'YTickLabel',lb);
      vline(0)
      xlabel('time re stim onset [s]')
      colormap(gca, cmap);
      set(gca, 'CLim', 0.5*max(abs(get(gca,'CLim')))*[-1 1])
      
      subplot(7,1,2:3)
      plot(T, M' + mod(gn(:,1),10)', 'LineWidth', 1.5)
      colorLines(flipud(cols))
      axis('tight')
      vline(0)
      set(gca, 'YTick',1:5, 'YTickLabel', num2cellstr(GipiLabel,2,'ipi '))
      
      subplot(7,1,4:5)
      plot(T, M' + floor(gn(:,1)/10)', 'LineWidth', 1.5)
      colorLines(flipud(cols))
      axis('tight')
      vline(0)
      set(gca, 'YTick',[1 2], 'YTickLabel', {'opto OFF', 'opto ON'})
      
      [~, baseSpdHist] = ghist(log2(rr.baseSpd), stiID, 48);
      [~, testSpdHist] = ghist(log2(rr.testSpd), stiID, 48);
      subplot(716)
      imagesc(baseSpdHist)
      title('base line speed')
      hline(5.5,'r')
      set(gca, 'YTick', 1:10, 'YTickLabel',lb);
      
      subplot(717)
      imagesc(testSpdHist)
      title('test speed')
      hline(5.5,'r')
      set(gca, 'YTick', 1:10, 'YTickLabel',lb);
      xlabel('log speed')
      drawnow
      if mfilename()
         figexp(['fig.opto/' playbackLists.stimName{fil}], 0.7, 1)
      end
      %%
      [M0,E0,G] = grpstats([rr.testSpd; rr.baseSpd]', stiID, {'nanmean', 'sem', 'gname'});
      G = str2double(G);
      M = reshape(M0(:,1),[],2);
      E = reshape(E0(:,1),[],2);
      Mbase = reshape(M0(:,2),[],2);
      Ebase = reshape(E0(:,2),[],2);
      X = unique(ipi)';
      
      clf
      subplot(121)
      [hL, hE] = myErrorBar(X,M,E);
      [hLbase, hEbase] = myErrorBar(X-1,Mbase,Ebase);
      set(hLbase, 'LineStyle', '--')
      xlabel('IPI [ms]')
      ylabel('speed [mm/s]')
      set([hL; hLbase], 'LineWidth', 2)
      set(gca, 'XTick', X)
      legend([hL; hLbase], {'test light ON', 'test light OFF', 'base light ON', 'base light OFF'}, 'Box','off')
      title(strrep(playbackLists.stimName{fil}, '_', ' '))
      axis('tight')
      
      [M,E,G] = grpstats(rr.testSpd-rr.baseSpd, stiID, {'nanmean', 'sem', 'gname'});
      G = str2double(G);
      M = reshape(M,[],2);
      E = reshape(E,[],2);
      X = unique(ipi)';
      subplot(122)
      [hL, hE] = myErrorBar(X,M,E);
      xlabel('IPI [ms]')
      ylabel('\Deltaspeed [mm/s]')
      set(hL, 'LineWidth', 2)
      set(gca, 'XTick', X)
      legend(hL, {'test-base light ON', ' test-base light OFF'}, 'Box','off')
      title(strrep(playbackLists.stimName{fil}, '_', ' '))
      axis('tight')
      hline(0)
      clp()
      if mfilename()
         figexp(['fig.opto/' playbackLists.stimName{fil} '_tune'], 1.0, 0.5)
      end
      %%
      allTune(fil).M = M;
      allTune(fil).E = E;
      allTune(fil).G = G;
      allTune(fil).X = X;
      allTune(fil).name = playbackLists.stimName{fil};
   catch ME
      disp(ME.getReport())
   end
end
%%
clf
cnt = 0;
for fil = 1:length(allTune)
   try
      token = strsplit(allTune(fil).name,'_');
      allTune(fil).genoType = token{2};
      allTune(fil).sex = token{4};
      allTune(fil).atr = token{3}(1)=='a';
      cnt = cnt+1;
      subplot(4,3,cnt)
      [hL, hE] = myErrorBar(allTune(fil).X,allTune(fil).M,allTune(fil).E);
      xlabel('IPI [ms]')
      ylabel('\Deltaspeed [mm/s]')
      set(hL, 'LineWidth', 2)
      set(gca, 'XTick', X)
      axis('tight')
      hline(0)
      legend(hL, {'light ON', 'light OFF'}, 'Box','off')
      title([allTune(fil).genoType ' ' allTune(fil).sex ' atr=' int2str(allTune(fil).atr)])
      clp()
   catch
      allTune(fil).genoType = '';
      allTune(fil).sex = '';
      allTune(fil).atr = nan;
   end
end
uniGenotype = unique({allTune.genoType});
badIdx = find(strcmp(uniGenotype,''))
uniGenotype(badIdx) = [];
for gen = 1:length(uniGenotype)
   uniGenotype{gen}
   find(contains({allTune.genoType}, uniGenotype{gen}));
end

clp()
if mfilename()
   figexp(['fig.opto/tune'], 1.0, 0.5)
end
