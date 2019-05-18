%% initialize fly tracking
% draw arena
% mark fly positions in initial frame
% calculate background and initialize cluster in initial frame
cc()
if ispc
%    cd Z:\jan\playback\dat
   baseDir = '';
elseif ismac
   baseDir = './dat';
end
COURTSHIP = ~isempty(strfind(cd,'courtship'));
LONGCHAMBER = ~isempty(strfind(cd,'longchamber'));
PLAYBACK = ~isempty(strfind(cd,'playback'));
MIC4 = ~isempty(strfind(cd,'4mic'));
% get all video files in subfolders
fileNames = [getFileNames(fullfile(baseDir, '**','*.mp4')); getFileNames(fullfile(baseDir, '**', '*.avi'))];
% clean file list
fileNames(~cellfun(@isempty,strfind(fileNames, 'Cmp'))) = [];
fileNames(~cellfun(@isempty,strfind(fileNames, 'fly'))) = [];
%%
for fil = length(fileNames):-1:1
   try
      clear fp
      %% get one global fp fpc{bx}ect for
      % estimating background, detecting chambers and flies
      disp(fileNames{fil})
      if exist([fileNames{fil}(1:end-4) '_init.mat'],'file')
         out = whos('-file',[ fileNames{fil}(1:end-4) '_init.mat']);
         if any(ismember({out.name}, 'gmmInit'))
            disp('   correct init file exists - skipping file!')
            continue
         end
      end
      if exist([ fileNames{fil}(1:end-4) '_res.mat'],'file')
         disp('   RES file exists - skipping file!')
         %          continue
      end
      clf
      disp('   loading video file.')
      fp = FlyPursuit([ fileNames{fil}]);
      if fp.NumberOfFrames<100, continue, end
      fp.initFrame = 1;%2000;
      colormap('gray')
      if COURTSHIP || MIC4
         fp.drawArenaPoly(fp.initFrame,.9);
         fp.nFlies = 2;
      elseif LONGCHAMBER
         disp('   estimating arena bounds.')
         fp.getBackGround(10);
         bw = fp.medianFrame>.8*mean(fp.medianFrame(:));
         bw = imclose(bw,strel('disk',5));
         % keep only biggest box
         bwl = bwlabel(bw);
         [cnt, bin] = hist(bwl(:), unique(bwl(:)));
         bw(bwl~=bin(argmax(cnt)))=0;
         bbox = regionprops(bw,'boundingbox','area','ConvexImage','PixelIdxList','PixelList','SubArrayIdx');
         bx = 1;
         boxPos = vertcat(bbox(bx).BoundingBox);
         fp.arenaX = [floor(boxPos(bx,2)) ceil(boxPos(bx,2)+boxPos(bx,4)) ceil(boxPos(bx,2)+boxPos(bx,4)) floor(boxPos(bx,2)) floor(boxPos(bx,2))];
         fp.arenaY = [floor(boxPos(bx,1)) floor(boxPos(bx,1)) ceil(boxPos(bx,1)+boxPos(bx,3)) floor(boxPos(bx,1)+boxPos(bx,3)) floor(boxPos(bx,1))];
         fp.boundsX = unique(limit(round(min(fp.arenaX):max(fp.arenaX)),1, fp.w));
         fp.boundsY = unique(limit(round(min(fp.arenaY):max(fp.arenaY)),1, fp.h));
         fp.arenaCrop = padarray(bbox(bx).ConvexImage,[1 1],0);
         fp.arena = bw;
         fp.w = length(fp.boundsX);
         fp.h = length(fp.boundsY);
      elseif PLAYBACK
         fp;
      else
         fp.initFrame = 8400;
         fp.drawArena(fp.initFrame);
      end
      %% initialize fly position
      if exist([fileNames{fil}(1:end-4) '_initPrepare.mat'], 'file') % start from guess
         disp('   loading guesses')
         load([fileNames{fil}(1:end-4) '_initPrepare.mat'])
         % remove positions that are too close to each other
         
         %%
         fp.getFrame(fp.initFrame);
         imagesc(fp.currentFrameOriginal);
         h = impoly(gca, position(argsort(position(:,1)),:));
         fcn = makeConstrainToRectFcn('impoly',get(gca,'XLim'),...
            get(gca,'YLim'));
         setPositionConstraintFcn(h,fcn);
         disp('   please fix them...')
         fp.pos = wait(h);
         fp.nFlies = size(fp.pos,1);
      else %% manually mark flies
         clf
         axis('off')
         disp('   mark fly positions. first female, then male.')
         fp.initFlies(fp.initFrame);
      end
      disp('   done.')
      gmmInit.mu = fp.pos;
      gmmInit.Sigma = repmat([10 0; 0 10],1,1,fp.nFlies);
      gmmInit.PComponents = ones(fp.nFlies,1)/fp.nFlies;
      fp.vr.clean();
      save([fileNames{fil}(1:end-4) '_init'], 'fp','gmmInit')
      fprintf(' saving.\n')
   catch ME
      disp(ME.getReport())
   end
end
