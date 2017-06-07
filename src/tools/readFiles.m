function rr = readFiles(fileList)
% initialize
rr.spdF = [];
rr.posF = [];
rr.oriF = [];
rr.flyID = [];
rr.recID = [];
rr.stiID = [];
rr.modID = [];
rr.FPS = [];
rr.PXperMM = [];
%%
for fil = 1:length(fileList)
   try
      try
         load(fileList{fil});
         fprintf( 'successfully loaded %s\n', fileList{fil})
         try % in some versions 'rDat' is called 'p'
            rDat = p;
         end
         
         if ~isfield(rr,'p')
            try
               rr.p = p;
            catch
               rr.p = rDat;
            end
         end
      catch
         warning( 'could not load %s', fileList{fil} )
         continue
      end
      
      try
         rr.newFs(fil) = newFs;
      catch
         rr.newFs(fil) = 10;
      end
      try
         rr.LEDerror(fil) = LEDerror;
      catch
         rr.LEDerror(fil) = -1;
      end
      if rr.LEDerror(fil)<100 && length(unique(stiID(~isnan(stiID))))==length(rDat.stimAll) && all(size(spdF))
         rr.spdF = [rr.spdF spdF];
         rr.posF = [rr.posF posF];
         rr.oriF = [rr.oriF oriF];
         rr.flyID = [rr.flyID flyID(1:size(spdF,2))];
         rr.recID = [rr.recID fil*ones(1,size(spdF,2))];
         rr.stiID = [rr.stiID stiID(1:size(spdF,2))];
         try
            rr.FPS = [rr.FPS FPS*ones(1,size(spdF,2))];
            rr.PXperMM = [rr.PXperMM (double(chamberSizePX)/double(chamberSizeMM))*ones(1,size(spdF,2))];
         catch
            warning('no FPS and PXperMM available')
            rr.FPS = [rr.FPS nan(1,size(spdF,2))];
            rr.PXperMM = [rr.PXperMM nan(1,size(spdF,2))];
         end
         try
            rr.modID = [rr.modID modID(1:size(spdF,2))];
         catch
            warning('no modID available')
            rr.modID = [rr.modID nan(1,size(spdF,2))];
         end
      else
         warning('empty OR wrong number of stims OR crappy LED')
      end
   catch ME
      disp(ME.getReport())
   end
end
%%
rr.recs = max(rr.recID);
rr.stis = max(rr.stiID);
rr.mods = max(rr.modID);
rr.nFlies = max(rr.recID + 1000*rr.flyID);
rr.fileList = fileList;

nanId = isnan(rr.stiID);
rr.recID(nanId) = [];
rr.flyID(nanId) = [];
rr.stiID(nanId) = [];
rr.modID(nanId) = [];
rr.FPS(nanId) = [];
rr.PXperMM(nanId) = [];
%
rr.spdF = rr.spdF(:, 1:length(rr.recID));
rr.posF = rr.posF(:, 1:length(rr.recID),:);
rr.oriF = rr.oriF(:, 1:length(rr.recID),:);


