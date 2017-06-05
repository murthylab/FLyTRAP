function varargout = myErrorBar(varargin)
% USAGE: [hLine,hError] = myErrorBar(X,Y,E, type)
% PARAMS: Y,E or X,Y,E, x times number or lines
%RETURNS: handles to line and error

% created 09/05/29 Jan Clemens

if nargin==2
   Y = varargin{1};
   E = varargin{2};
   X = (1:size(Y,1))';
else
   X = varargin{1};
   Y = varargin{2};
   E = varargin{3};
end



cols = get(gca,'ColorOrder');%lines(size(Y,2));
cols = repmat(cols, ceil(size(Y,2)/size(cols,1)),1);% make sure we have enough colors

if size(Y,2) ~= size(X,2)
   X = repmat(X,size(Y,2),1)';
end

hold on
for y = 1:size(Y,2)
   hLine(y,:) = plot(X(:,y),Y(:,y),'.-','Color',cols(y,:));   
   hError(y,:) = plot([X(:,y) X(:,y)]',[Y(:,y)-E(:,y) Y(:,y)+E(:,y)]','Color',cols(y,:));
end

if nargout>0
    varargout{1} = hLine;
    varargout{2} = hError;
end

