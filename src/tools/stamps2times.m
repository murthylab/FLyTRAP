function frameTimes = stamps2times(timeStamps)
%shutterTime goes from 0-128 and again from 0. frameTimes is correcting for that - just monotonic increase of shutter time

% convert timestamps to shuttertimes (in seconds?)
shutterTime = timeStamps(6,:) + timeStamps(4,:)/8000;%Time of "Shutter OFF" for each frame the camera was capturing
nLastShutterTime = find(shutterTime(1:end-1)==0 & shutterTime(2:end)==0,1)-1;%Sometimes there a single zero within shutterTime, therefore check from 2 zeros

if isempty(nLastShutterTime)
   nLastShutterTime = size(shutterTime,2);
end

frameTimes = shutterTime(1:nLastShutterTime);

% if ~isempty(nLastShutterTime)
%    frameTimes = zeros(nLastShutterTime,1);
% else
%    frameTimes = zeros(size(shutterTime,2),1);
% end

for i=2:nLastShutterTime
   if shutterTime(i-1)-shutterTime(i)>127
     frameTimes(i:end)=frameTimes(i:end)+128;
   elseif shutterTime(i)==0
       frameTimes(i)= NaN;
   end
end





