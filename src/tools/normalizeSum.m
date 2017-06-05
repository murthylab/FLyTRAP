function data = normalizeSum(data)
%normalize data, such sum(data)=1
%   data = normalizeSum(data)
%
%args
%   data
%returns
%   normalized data
%
% created 20130209 jan
if (size(data,1)==1 || size(data,2)==1)
   data = data/nansum(data);
else
   for cat = 1:size(data,1)
      data(cat,:) = data(cat,:)/(nansum(data(cat,:)));
   end
end

