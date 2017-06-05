function x = sem(x, varargin)
%x = sem(x, [dim])
if nargin==1
   dim = 1;
else
   dim = varargin{1};
end
x = squeeze(nanstd(x,[],dim)./sqrt(size(x,dim)));