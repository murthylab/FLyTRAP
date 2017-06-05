rr.newFs = 10;
% disp(rr.p.stimFileName)
rr.stimIdx = 30*mode(rr.newFs):40*mode(rr.newFs);
rr.baseLineIdx = 2*mode(rr.newFs):28*mode(rr.newFs);
rr.badRecording = [];%[2 8];
rr.xLabel = '';
rr.x = num2cellstr(1:rr.stis);
switch stimStrg
   case 'YakSan_IPI'
      rr.xLabel = 'ipi [ms]';
      rr.x = num2cellstr([50 80 100 130 170]);
   case 'carrierLong'
      rr.xLabel = 'pulse carrier frequency [Hz]';
      rr.x = num2cellstr([100 200 300 500 800]);
      rr.stimIdx = 33*mode(rr.newFs):37*mode(rr.newFs);
   case {'ipiTune', 'ipiTuneDense'}
      rr.xLabel = 'ipi [ms]';
      rr.x = num2cellstr([16:20:96]);
      rr.badRecording = [2:4];
   case {'nipiTune', 'ipiTuneCSTullyFemale', 'ipiTuneCSTullyMale'}
      rr.xLabel = 'ipi [ms]';
      rr.x = num2cellstr([16:20:96]);
   case 'ipiTuneGRP'
      rr.xLabel = 'ipi [ms]';
      rr.x = num2cellstr([16:20:96]);
      rr.badRecording = [2];
   case 'ipiDur'
      rr.xLabel = 'N pulses';
      rr.x = num2cellstr(log2(2.^(4:9)));
      rr.badRecording = [1 2];
      rr.stimIdx = 450:630;
      rr.baseLineIdx = 20:400;
   case 'ipiDur2'
      rr.xLabel = 'N pulses';
      rr.x = num2cellstr(log2(2.^(2:7)));
      rr.stimIdx = 300:630;
      rr.baseLineIdx = 20:280;
   case 'DURfull'
      rr.xLabel = 'N pulses';
      rr.x = num2cellstr((2.^(2:9)));
      rr.stimIdx = 450:780;
      rr.baseLineIdx = 20:270;
   case 'IBI'
      rr.xLabel = 'IBI';
      rr.x = num2cellstr(log(rr.p.silencePre));
      rr.badRecording = rr.stiID>4;
      rr.stimIdx = 300:340;
      rr.baseLineIdx = 200:280;%[];%1:300;
      % rearrange such that stim is flush with end
      for ii = 1:size(rr.spdF, 2)
         idx = find(isnan(rr.spdF(:,ii)),1,'first');
         rr.spdF(end-idx+1:end,ii) = rr.spdF(1:idx,ii);
         rr.spdF(1:idx,ii) = nan;
      end
   case {'SINEfreq'; 'SINEfreqSoft'}
      rr.x = num2cellstr([100 200 300 500 800]);
      rr.xLabel = 'sine freq [Hz]';
      rr.badRecording = [5];% [2 3 4 5 9];
      rr.stimIdx = 310:380;
      rr.baseLineIdx = 20:280;%[];%1:300;
      
   case 'IPInp'
      rr.x = num2cellstr([16 36 56 76 96]);
      rr.xLabel = 'IPI [ms]';
      rr.stimIdx = 380:460;
      rr.baseLineIdx = 20:360;%[];%1:300;
   case 'PPAUTune2'
      rr.x = num2cellstr([4 8 20 32 64]);
      rr.xLabel = 'pause duration [ms]';
   case 'intensity3'
      rr.x = rr.p.intensity;
      rr.xLabel = 'intensity [mm/s]';
   case 'IPItuneSP'
      rr.xLabel = 'ipi [ms]';
      rr.x = num2cellstr([16:20:96]);
      rr.stimIdx = 30*mode(rr.newFs):36*mode(rr.newFs);
   case 'ipiTune2'
      rr.xLabel = 'ipi [ms]';
      rr.x = num2cellstr([16:20:96]);
      rr.stimIdx = 30*mode(rr.newFs):36*mode(rr.newFs);
   case {'ipiTune_contextBadShortIPI'; 'ipiTune_contextGood'; 'ipiTune_contextBad'; 'ipiTune_contextSwitch'}
      rr.stimIdx = 30*mode(rr.newFs):34*mode(rr.newFs);
   case 'ipiTuneMale'
      rr.stimIdx = 30*mode(rr.newFs):36*mode(rr.newFs);
      rr.xLabel = 'ipi [ms]';
      rr.x = num2cellstr([16:20:96]);
   case 'pulseSine'
      rr.x = {'sin-pul', 'pul-sin', 'sin', 'pul'}';
   case {'pulseSine2', 'pulseSine2male'}
      rr.x = {'sin100-ipi36', 'ipi36-sin100', 'sin250-ipi36', 'ipi36-sin250', 'sin100-4s', 'sin100-2s', 'sin250-4s', 'sin250-2s', 'ipi36-2s', 'ipi36-4s'}';
   case 'durTuneMale'
      rr.x = {'4' '8' '16' '24' '32'}'
      rr.xLabel = 'pulse duration [ms]';
   case {'ipiTune41_female', 'ipiTune71_female', 'ipiTune41_male', 'ipiTune71_male', 'ipiTuneCTRL_female', 'ipiTuneCTRL_male'}
      rr.xLabel = 'ipi [ms]';
      rr.x = num2cellstr([16:20:96]);
   case {'sineTuneMale', 'sineTuneFemale', 'sineTune41_female', 'sineTune71_female', 'sineTune41_male', 'sineTune71_male', ...
         'sineTuneCTRL_female', 'sineTuneCTRL_male','sineTuneCSTullyFemale','sineTuneCSTullyMale'}
      rr.x = num2cellstr([100 200 300 500 800]);
      rr.xLabel = 'sine frequency [Hz]';
      rr.stimIdx = 30*mode(rr.newFs):36*mode(rr.newFs);
   case {'intensityNM91female'}
%       rr.badRecording = 9;
end
% rr.stiID = circshift(rr.stiID,[0, length(unique(rr.flyID))]);
%    rr.stiID(1:length(unique(rr.flyID))) = 1;