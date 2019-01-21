if ~ismac
   baseDir = '';
   tid = getTaskID();
   plotResults = false;
else
   baseDir = './';%'dat/160419_1316/';%'dat/140317_1018/';%
   tid = 1;%getTaskID()
   plotResults = true;
   colormap(gray);
end
fileList = dir([baseDir '*_init.mat']);
fileNames = {fileList.name}'

COURTSHIP = ~isempty(strfind(cd,'courtship'));
LONGCHAMBER = ~isempty(strfind(cd,'longchamber'));
PLAYBACK = ~isempty(strfind(cd,'playback'));
MIC4 = ~isempty(strfind(cd,'4mic'));

p.FOREGROUND_THRESHOLD = 10;
if COURTSHIP
   maxChambers = 1;
   p.saveFlyBox = true;
   p.readLED = true;
elseif MIC4
   maxChambers = 1;
   p.saveFlyBox = true;
   p.readLED = false;
   p.FOREGROUND_THRESHOLD = 50;
elseif LONGCHAMBER
   maxChambers = 1;
   p.saveFlyBox = false;
   p.readLED = true;
elseif PLAYBACK
   maxChambers = 12;
   p.saveFlyBox = false;
   p.readLED = true;
else
   maxChambers = 1;
   p.saveFlyBox = false;
   p.readLED = false;
end

fil = ceil(tid/maxChambers)
chamberNumber = mod(tid-1, maxChambers)+1

%%
disp(fileNames{fil})
if exist([baseDir fileNames{fil}(1:end-9) '_res_' int2str(chamberNumber) '.mat'],'file')
   load([baseDir fileNames{fil}(1:end-9) '_res_' int2str(chamberNumber) '.mat'])
   if mean(~isnan(p.LEDvalues))>.8
      disp('results exist - skipping file!')
      return
   else
      disp('results too short - retrying')
   end
end

load([baseDir fileNames{fil}]);
if COURTSHIP || LONGCHAMBER || MIC4
   fpc{chamberNumber} = fp;
end

if length(fpc)<chamberNumber
   disp(['no chamber #' int2str(chamberNumber) ' in this recording'])
   return
end
%%
if PLAYBACK
   gmmInit = gmmBox{chamberNumber};
end
[fileDir, fileNam, fileExt] = fileparts(strrep(fpc{chamberNumber}.vFileName, '\','/'));% get unix filesep so it works when initializing in windows
fp = FlyPursuit([baseDir fileNam fileExt]);

% if isunix && ~ismac % use fastscratch instead of jukebox as temp
%    fp.vr.tempFolder = '/jukebox/scratch/janc/';
%    fp.vr.tempName = tempname(fp.vr.tempFolder);
% end

fp.initFrame = fpc{chamberNumber}.initFrame;
fp.nFlies = fpc{chamberNumber}.nFlies;
fp.arena = fpc{chamberNumber}.arena;
fp.arenaCrop = fpc{chamberNumber}.arenaCrop;
fp.arenaY = fpc{chamberNumber}.arenaY;
fp.arenaX = fpc{chamberNumber}.arenaX;
fp.boundsY = fpc{chamberNumber}.boundsY;%unique(limit(round(min(fp.arenaY):max(fp.arenaY)),1, fp.h));
fp.boundsX = fpc{chamberNumber}.boundsX;%unique(limit(round(min(fp.arenaX):max(fp.arenaX)),1, fp.w));
fp.w = length(fp.boundsX);
fp.h = length(fp.boundsY);

clear fpc;

%% mark file as work-in-progress
wipFile = [baseDir fileNames{fil}(1:end-9) '-' int2str(chamberNumber) '_wip.mat'];
message = ['Skipping file ' fileNames{fil}(1:end-9) ' - work-in-progress elsewhere. Delete ' wipFile ' to force it to run again.'];
assert(~exist(wipFile, 'file'), message);
save(wipFile, 'message')
%% init fly box saving
if p.saveFlyBox
   fprintf('  will save fly box.\n')
   vw = VideoWriter([baseDir fileNam '_fly.mj2'],'Motion JPEG 2000');% video writer
   set(vw,'FrameRate', fp.vr.FrameRate, 'CompressionRatio', 12);
   vw.open()
   p.flyBoxWidthIdx = -60:61;
   p.flyBoxHeightIdx = -60:61;
else
   fprintf('  will NOT save fly box.\n')
end
%% init LED readout
if p.readLED
   fprintf('  will read-out LED state.\n')
   if COURTSHIP
      p.LEDidxX = 900:960;
      p.LEDidxY = 1050:1150;
   end
   if PLAYBACK
      p.LEDidxX = 550:fp.vr.Height;
      p.LEDidxY = 1:500;
   end
   if LONGCHAMBER
      p.LEDidxX = 170:fp.vr.Height;
      p.LEDidxY = 1:100;
   end
   p.LEDvalues= nan(fp.NumberOfFrames, fp.colorChannels);
else
   fprintf('  will NOT read-out LED state.\n')
end
%%
fprintf('   estimating background...')
if ~ismac
   if LONGCHAMBER
      fp.getBackGround(500);
   else
      fp.getBackGround(1000);
   end
else
   fp.getBackGround(10);
end
fprintf(' done.\n')
%%
if size(fp.arena,1)<size(fp.medianFrame,1)
   fp.arena(end+1,:) = 0;
end
if size(fp.arena,2)<size(fp.medianFrame,2)
   fp.arena(:,end+1) = 0;
end
%% init tracking

% TODO - add SPATIAL dimension - mm/px!!
fp.initTracker(fp.initFrame, gmmInit)
fp.samplesPerFly = 1000;
fp.arenaCrop = imfilter(single(fp.arenaCrop), fspecial('gauss',20,3))>0.9;%imerode(fp.arena,strel('disk',4));
fp.seNew = strel('disk',80);
fp.seOld = strel('disk',80);
fp.foreGroundThreshold = p.FOREGROUND_THRESHOLD;%7

if isa(fp.vr, 'VideoReaderFFMPEG') % enable buffered mode since we're reading consecutive frames
   fp.vr.buffered = true;
   fp.vr.bufferSize = 10;
end

% track
tic;
while fp.currentFrameIdx<fp.NumberOfFrames
   try
      fp.trackNextFrame( plotResults );
      if mod(fp.currentFrameIdx,1000)==0
         fprintf('%d / %d frames tracked in %1.0f seconds\n', fp.currentFrameIdx, fp.NumberOfFrames, toc/1);
         tic;
      end
      
      % extract state of stimulus-ON-LED
      if p.readLED
         p.LEDvalues(fp.currentFrameIdx,:) = mean(mean(fp.currentFrameOriginal(p.LEDidxX, p.LEDidxY,:),1),2);
      end
      % fly position in original frame coordinates
      if p.saveFlyBox
         flyX = round(fp.tracks(fp.currentFrameIdx,:,1));% + min(fp.boundsX));
         flyY = round(fp.tracks(fp.currentFrameIdx,:,2));% + min(fp.boundsY));
         flyFrame = fix.extractFlyBox(fp.currentFrame, flyY, flyX, p.flyBoxWidthIdx, p.flyBoxHeightIdx);
         vw.writeVideo(uint8(flyFrame));
      end
   catch ME
      fprintf('error at frame %d \n', fp.currentFrameIdx);
      disp(ME.getReport());
   end
end

if p.saveFlyBox
   vw.close();
end
%% save results
if isa(fp.vr, 'VideoReaderFFMPEG') % delete temporary files
   fp.vr.clean();
end
save([baseDir fileNames{fil}(1:end-9) '_res_' int2str(chamberNumber)], 'fp','p')
delete( wipFile )

