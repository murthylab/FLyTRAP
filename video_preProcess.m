
fileName = getFileNames('*init.mat');
%%
for fil = 1:length(fileName)
    trunk = fileName{fil}(1:end-9);
    disp(['PRE-processing ' trunk])
    load([trunk '_init.mat'], 'fp','gmmInit')
    %% fix VR
    [fileDir, fileNam, fileExt] = fileparts(strrep(fp.vFileName, '\','/'));% get unix filesep so it works when initializing in windows
    fp.vFileName = [fileNam fileExt];
    fp.vr = VideoReaderFFMPEG(fp.vFileName);
    %%
    fp.getBackGround(100);
    clear fpc
    bw = fp.medianFrame>.8*mean(fp.medianFrame(:));
    bw = imclose(bw,strel('disk',5));
    bw = imdilate(bw,strel('disk',5));
    %%
    bbox = regionprops(bw,'boundingbox','area','ConvexImage','PixelIdxList','SubArrayIdx');
    % remove 'specks' ('small chambers')
    minChamberArea = 20000;%px
    bbox([bbox.Area]<minChamberArea) = [];
    
    boxPos = vertcat(bbox.BoundingBox);
    cmap = limit(jet(length(bbox))-0.2);
    if ismac || ispc
        clf
        subplot(211)
        colormap(gray)
        imagesc(bw)
        hold on
    end
    boxIdx = [];
    %%
    se = strel('disk',4);
    fprintf('  detecting flies in individual chambers ');
    for bx = 1:size(boxPos,1)
        %grow box by 4px in each direction
        boxPos(bx,1:2) = limit(boxPos(bx,1:2) -4, 1, max(fp.boundsY));
        boxPos(bx,3:4) = limit(boxPos(bx,3:4) +8, 1, max(fp.boundsX));
        % find which boxes are occupied flies
        %boxIdx{bx} = find(inpolygon(gmmInit.mu(:,1), gmmInit.mu(:,2), [boxPos(bx,1) boxPos(bx,1)+boxPos(bx,3)], [boxPos(bx,2) boxPos(bx,2)+boxPos(bx,4)]));
        boxIdx{bx} = find(inpolygon(fp.pos(:,1), fp.pos(:,2), ...
            [boxPos(bx,1) boxPos(bx,1)+boxPos(bx,3) boxPos(bx,1)+boxPos(bx,3) boxPos(bx,1)], ...
            [boxPos(bx,2) boxPos(bx,2)              boxPos(bx,2)+boxPos(bx,4) boxPos(bx,2)+boxPos(bx,4)]));
        % and proccess only those
        if ~isempty(boxIdx{bx})
            try
                fprintf('.')
                if ismac || ispc
                    subplot(211)
                    hl = rectangle('Position',boxPos(bx,:),'LineWidth',4,'EdgeColor',cmap(bx,:));
                    plot(fp.pos(boxIdx{bx},1), fp.pos(boxIdx{bx},2),'o','Color',cmap(bx,:),'MarkerSize',24)
                    mySubPlot(2,length(bbox), 2, bx)
                    imagesc(imcrop(bw, boxPos(bx,:)))
                    hold on
                    plot(fp.pos(boxIdx{bx},1)-boxPos(bx,1), fp.pos(boxIdx{bx},2)-boxPos(bx,2),'o','Color',cmap(bx,:),'MarkerSize',24)
                    drawnow
                end
                fpc{bx} = FlyPursuit( fp.vr.vFileName	);
                fpc{bx}.arena = bbox(bx).ConvexImage;%imdilate(bbox(bx).ConvexImage,se);% grow convexhull, too
                fpc{bx}.arena = padarray(fpc{bx}.arena,[4 4],0);
                fpc{bx}.arena(end+1,end+1) = 0;
                fpc{bx}.arena = imcrop(fpc{bx}.arena, [0 0 fpc{bx}.h fpc{bx}.w]);
                mask = imerode(fpc{bx}.arena,strel('disk',4));
                fpc{bx}.arenaCrop = mask;
                % crop to max frame size
                % needed to switch stuff
                fpc{bx}.arenaX = [boxPos(bx,2) boxPos(bx,2)+boxPos(bx,4) boxPos(bx,2)+boxPos(bx,4) boxPos(bx,2) boxPos(bx,2)];
                fpc{bx}.arenaY = [boxPos(bx,1) boxPos(bx,1) boxPos(bx,1)+boxPos(bx,3) boxPos(bx,1)+boxPos(bx,3) boxPos(bx,1)];
                fpc{bx}.boundsX = unique(limit(round(min(fpc{bx}.arenaX):max(fpc{bx}.arenaX)),1, fpc{bx}.w));
                fpc{bx}.boundsY = unique(limit(round(min(fpc{bx}.arenaY):max(fpc{bx}.arenaY)),1, fpc{bx}.h));
                fpc{bx}.w = length(fpc{bx}.boundsX);
                fpc{bx}.h = length(fpc{bx}.boundsY);
                fpc{bx}.arena = imcrop(fpc{bx}.arena, [0 0 fpc{bx}.h fpc{bx}.w]);
                fpc{bx}.arenaCrop = imcrop(fpc{bx}.arenaCrop, [0 0 fpc{bx}.h fpc{bx}.w]);
                
                fpc{bx}.initFrame = fp.initFrame;
                fpc{bx}.getBackGround(10);
                %%
                frame = fpc{bx}.getFrames(fpc{bx}.initFrame);
                frame = fpc{bx}.getForeGround(frame);
                if ismac || ispc
                    imagesc(frame)
                    drawnow
                end
                %%
                fpc{bx}.nFlies = length(boxIdx{bx});
                fpc{bx}.samplesPerFly = 400*fpc{bx}.nFlies;
                fpc{bx}.gmmStart = [];
                fpc{bx}.gmmStart.mu = bsxfun(@minus,fp.pos(boxIdx{bx},:), boxPos(bx,1:2));
                fpc{bx}.gmmStart.Sigma = repmat([10 0; 0 10],1,1,length(boxIdx{bx}));
                fpc{bx}.gmmStart.PComponents = ones(length(boxIdx{bx}),1)/length(boxIdx{bx});
                
                gmmBox{bx} = fpc{bx}.clusterFrame(frame);
                if ismac || ispc
                    fpc{bx}.plotCluster(gmmBox{bx})
                    drawnow
                end
                fpc{bx}.vr.clean();
            catch ME
                disp(ME.getReport())
            end
        end
        fp.vr.clean();
        save([trunk '_init.mat'], 'fp','fpc','gmmBox','gmmInit','bbox')
        fprintf(' saving.\n')
    end
end