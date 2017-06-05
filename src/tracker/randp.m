function [X, Y] = randp(empPdf,varargin)
% [X, Y] = randp(empPdf,varargin)
% sample from distribution
cpdf = cumsum(empPdf(:))/sum(empPdf(:));

% replaced: [uniCpdf, uniIdx] = unique(cpdf);
% by this since cpdf is already sorted and sorting is the bottleneck
uniIdx = [true;diff(cpdf)>0];
uniCpdf = cpdf(uniIdx);

x = 1:length(cpdf);
x = x(uniIdx);
seeds = rand(varargin{:});
linIdx = interp1(uniCpdf, x, seeds, 'nearest', 0);
[Y, X] = ind2sub(size(empPdf), linIdx');
