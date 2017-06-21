% this should do the syncing between
% song recording/playback for all types of recordings!!
% ?? maybe also call getLocomotorFeatures ??
%%
fileName = getFileNames('*_init.mat');
for fil = 1:length(fileName)
   try
      %% fix delay
      trunk = fileName{fil}(1:11);
      
      [fileDir, fileNam, fileExt] = fileparts(fileName{fil});
      load(fullfile(fileDir, [trunk 'vDat.mat']));
      disp(['POST-processing ' fileName(1:end-5)])
      
      if ~exist('rDat','var')
         disp('no RDAT - normalize file')
      end
      
      try
         disp(rDat.stimFileName)
      catch
         if exist('table','class')
            disp(rDat.ctrl.stimFileName)
         end
      end
      newFs = 10;%Hz
      
      thisResFiles =  getFileNames([fileNam(1:end-5) '_res_*']);
      if length(thisResFiles)<1
         fprintf('   no results yet in %s\n', fileNam)
         continue
      end
      
      clear res progress;
      for rs = 1:length(thisResFiles)
         disp(thisResFiles{rs})
         res(rs) = load(fullfile(fileDir, thisResFiles{rs}));
         progress(rs) = mean(~isnan(res(rs).p.LEDvalues));
      end
      clear r
      completeIdx = argmax(progress);
      r  = res(completeIdx).p;
      fp = res(completeIdx).fp;
      
      r.tracks = [];
      r.area = [];
      r.orientation = [];
      for rs = 1:length(res)
         r.tracks(:,end+(1:size(res(rs).fp.tracks,2)),:) = res(rs).fp.tracks;
         r.area(:,end+(1:size(res(rs).fp.tracks,2)),:) = res(rs).fp.area;
         r.orientation(:,end+(1:size(res(rs).fp.tracks,2)),:) = res(rs).fp.orientation;
      end
      nFlies = size(r.tracks,2);
      % optoState 
      lg = readtable(fullfile(fileDir, [trunk 'log.txt']), 'Delimiter', '\t');
      modeVal = lg.MODE;
      %% convert px/frame to mm/s
      chamberSizeMM = 50;%mm - as measured
      chamberSizePX = fp.w;%px - as detected in video
      FPS = rDat.FPS;
      %% find stimulus onsets based on LED readout
      if rDat.video==0 | strcmpi(rDat.video,'python') % load python time stamps...
         timeStamps = h5read([fileNam(1:end-5) '_timeStamps.h5'], '/timeStamps');
         % actualFrameTimes = (timeStamps(1,fp.initFrame:length(r.LEDvalues)) - timeStamps(1,1))'*1000; % use python clock
         actualFrameTimes = stamps2times( timeStamps )*1000; % use frame embedded time stamps - more accurate!
      else
         actualFrameTimes = rDat.frameTimes(fp.initFrame:end)'*1000;% true frame times in ms
      end
      regularFrameTimes = (actualFrameTimes(1):1000/newFs:actualFrameTimes(end));% grid given by newFs
      cnt=0;
      % try a bunch of thresholds and select the one that conforms best with
      % the expected sequence of stimulus intervals (based on stimulus
      % durations)
      thresholds = [.66 1 1.5 2 5 10];
      clear idx;
      match = inf*ones(1,100);
      
      % FIX:
      % id LEDon sequentially - biasing search by expected time of next
      % stimulus!! - make robust to skips
      
      for typ = 1:3
         % try with raw LED trace or with LED envelope
         LEDvalues = r.LEDvalues(fp.initFrame:end);
         if typ==2 || typ==3
            LEDvalues = conv(abs(LEDvalues), normalizeSum(gausswin(20,3)),'full');
            LEDvalues = LEDvalues(1:end-19);
            LEDvalues(isnan(LEDvalues)) = 0;
         end
         LEDvalues = LEDvalues - nanmedian(LEDvalues);
         LEDvalues(fp.initFrame) = LEDvalues(fp.initFrame+1); % why? to get rid of onset peaks?
         
         if isfield(rDat, 'stiStartSample')
            stis = rDat.sti;
         else % for vids recorded with older version
            stis = [1 rDat.sti];% need to add first stimulus - always started with stim #1 but did not put in rDat.sti since stim was queued outside of callback
         end
         
         stiLen = cellfun(@length, rDat.stimAll);
         if isfield(rDat, 'selectedStimulus')
            stiLenSeq = mapVal(stis , rDat.selectedStimulus, stiLen);
         else % for vids recorded with older version
            stiLenSeq = mapVal(stis , sort(unique(rDat.sti)), stiLen);
         end
         
         if typ==3
            expectedStimStart = cumsum(stiLenSeq)'/10;
            %% extimate global delay between VID and DAQ
            LEDvaluesRegular = interp1(actualFrameTimes(fp.initFrame+ (0:length(LEDvalues)-1)), LEDvalues, regularFrameTimes, 'linear');
            stimOnsets = zeros(size(LEDvaluesRegular));
            stimOnsets( floor(expectedStimStart/1000*newFs)) = 1;
            [xc, lags] = xcov(LEDvaluesRegular,stimOnsets,mean(lg.silencePre)/1000*newFs);
            delay = lags(argmax(xc))*1000/newFs;% ms
            clf
            plot(lags, xc)
            %%
            clf
            plot(actualFrameTimes(fp.initFrame+ (0:length(LEDvalues)-1))/100,LEDvalues,'.r')
            hold on
            plot(LEDvaluesRegular)
            plot((expectedStimStart+delay)/100,zeros(size(expectedStimStart))+0.5,'x')
            %%
            clf
            for tr = 1:length(thresholds)
               cnt = cnt+1;
               resOns = [];
               for sti = 1:length(stiLenSeq)
                  try
                     thisEpoch = LEDvaluesRegular( round((expectedStimStart(sti)+delay)/100) + (-20:50-1));
                     [~, loc] = findpeaks(diff(thisEpoch), 'MinPeakHeight', thresholds(tr)/1000, 'NPeaks', 1);
                     resOns(sti) = loc + round((expectedStimStart(sti)+delay)/100) - 20;
                  catch
                     resOns(sti) = nan;
                  end
               end
               %
               if ispc || ismac
                  clf
                  subplot(3,4,1:3)
                  plot(diff(LEDvaluesRegular))
                  hold on
                  plot(resOns, ones(size(resOns)),'o')

                  subplot(3,4,5:7)
                  %                      plot(diff(LEDvaluesRegular)>thres)
                  %                      hold on
                  %                      plot(resOns, (1:length(resOns))/length(resOns),'.')
                  subplot(1,4,4)
                  hist(diff(resOns),64)
                  axis(gcas,'tight')
                  vline(stiLen/1000, 'r');
                  drawnow
               end
               idx{cnt} = resOns;
               %
               minLen = min(length(resOns), length(stiLenSeq));
               matchRMSE(cnt) = sqrt(nanmean( (stiLenSeq(1:minLen-1)/1000 - diff(resOns(1:minLen))).^2 ));
               
               if ispc || ismac
                  subplot(3,4,9:11)
                  plot(stiLenSeq/1000,'.-k', 'MarkerSize', 12)
                  hold on
                  plot(diff(resOns),'o-')
                  axis(gcas,'tight')
                  drawnow
               end
            end
         else
            for tr = 1:length(thresholds)
               try
                  cnt = cnt+1;
                  thres = thresholds(tr)*max(LEDvalues)/100;%5*max(LEDvalues)/100;
                  resOns = find(diff(LEDvalues)>thres);
                  resOns(limit(find(diff(resOns)<400)+1,1,inf)) = [];
                  % convert to time using actual frame times
                  actualOnsetTimes = actualFrameTimes(resOns);
                  actualOnsetTimes(actualOnsetTimes<2000) = [];
                  if ispc || ismac
                     clf
                     subplot(3,4,1:3)
                     plot(diff(LEDvalues))
                     hold on
                     plot(resOns, ones(size(resOns)),'o')
                     subplot(3,4,5:7)
                     plot(diff(LEDvalues)>thres)
                     hold on
                     plot(resOns, (1:length(resOns))/length(resOns),'.')
                     subplot(1,4,4)
                     hist(diff(actualOnsetTimes),64)
                     hold on
                     vline(stiLen/10, 'r');
                     axis(gcas,'tight')
                     drawnow
                  end
                  % onsets in terms of actual frame times - now convert to samples in fly tracks by finding nearest
                  for ons = 1:length(actualOnsetTimes)
                     idx{cnt}(ons) = findnearest(actualOnsetTimes(ons), regularFrameTimes);
                  end
                  resOns = idx{cnt};
                  if ispc || ismac
                     subplot(3,4,9:11)
                     plot(stiLenSeq/1000,'.-k', 'MarkerSize', 12)
                     hold on
                     plot(diff(resOns),'o-')
                     axis(gcas,'tight')
                     drawnow
                  end
                  minLen = min(length(resOns), length(stiLenSeq));
                  matchRMSE(cnt) = sqrt(nanmean( (stiLenSeq(1:minLen-1)/1000 - diff(resOns(1:minLen))).^2 ));
               catch ME
                  disp(ME.getReport())
               end
            end
         end
      end
      resOns = idx{argmin(matchRMSE)};
      LEDerror = matchRMSE(argmin(matchRMSE));
      fprintf('best match with stim sequence RMSE: %1.2f ms\n', LEDerror/newFs*1000)
      %% if playback - reshape data to get trial-by-trial traces
      pos = r.tracks;                        % fly positions - px for each frame
      
      for fly = 1:nFlies
         for dd = 1:2
            pos(:,fly,dd) = medfilt1(pos(:,fly,dd), 5);
         end
      end
      
      ori = r.orientation;                   % fly orientation
      spd = sqrt(sum(diff(pos,[],1).^2,3));  % calc speed - in px/frame
      spd = [spd(1,:); spd];                 % prepend to keep array size consistent
      spd = spd(fp.initFrame:end,:);         % keep only speeds for which we have valid frames
      
      % interpolate fly behaviors to a regular grid
      resSpd = zeros(length(regularFrameTimes), nFlies);
      resPos = zeros(length(regularFrameTimes), nFlies, 2);
      resOri = zeros(length(regularFrameTimes), nFlies, 2);
      for fly = 1:nFlies
         filtSpd = medfilt1(spd(:,fly),11);         % filter to get rid of spikes=tracking errors
         resSpd(:,fly) = interp1(actualFrameTimes, filtSpd, regularFrameTimes);
         for dd = 1:2
            resPos(:,fly,dd) = interp1(actualFrameTimes, pos(:,fly, dd), regularFrameTimes);
            resOri(:,fly,dd) = interp1(actualFrameTimes, pos(:,fly, dd), regularFrameTimes);
         end
      end
      
      % reshape speed to trials
      spdF = nan(length(-30*newFs:60*newFs),(length(resOns)-1)*nFlies);
      posF = nan(length(-30*newFs:60*newFs),(length(resOns)-1)*nFlies, 2);
      oriF = nan(length(-30*newFs:60*newFs),(length(resOns)-1)*nFlies, 2);
      flyID = nan(1,(length(resOns))*nFlies);
      stiID = nan(1,(length(resOns))*nFlies);
      modID = nan(1,(length(resOns))*nFlies);
      cnt = 0;
      for ons = 1:length(resOns)
         try
            tmp = resSpd(resOns(ons) + (-30*newFs:60*newFs),:);
            spdF(1:length(tmp), cnt + (1:nFlies)) = tmp;
            
            tmp = resPos(resOns(ons) + (-30*newFs:60*newFs),:,:);
            posF(1:length(tmp), cnt + (1:nFlies), :) = tmp;
            
            tmp = resOri(resOns(ons) + (-30*newFs:60*newFs),:,:);
            oriF(1:length(tmp), cnt + (1:nFlies), :) = tmp;
            
            flyID(1, cnt + (1:nFlies)) = 1:nFlies;
            stiID(1, cnt + (1:nFlies)) = stis(ons);
            modID(1, cnt + (1:nFlies)) = modeVal(ons);
            cnt = cnt + nFlies;
         catch ME
            warning(ME.getReport())
         end
      end
      if ispc || ismac
         subplot(4,1,1:3)
         imagesc(spdF')
         vline(300)
         subplot(414)
         plot(grpstats(spdF',stiID(1:size(spdF,2)))')
         axis(gcas,'tight')
         vline(300)
         drawnow
      end
      %%
      fprintf('saving to %s\n', fullfile('../../res/', [fileNam(1:end-5) '_spd']) )
      save(fullfile('/jukebox/murthy/jan/playback/res/', [fileNam(1:end-5) '_spd']), ...
         'spdF', 'posF', 'oriF', 'rDat', 'flyID', 'stiID', 'modID', 'newFs', 'resOns', 'LEDerror', 'chamberSizePX', 'chamberSizeMM', 'FPS')
      %%
      %video_cleanup()
      %system(sprintf('mv -rf %s /jukebox/murthy/jan/playback/dat.processed/', fileDir))
   catch ME
      disp(ME.getReport())
   end
end