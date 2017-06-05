function varargout = mySubPlot(X,Y,x,y)
%modified subplot
%USAGE:
%  h = mySubPlot(X,Y,x,y)
%
%ARGS:
%  X - number of columns
%  Y - number of rows
%  x - current column
%  y - current row
%RETURNS
%  h - handle to the axis created

%created 07/08/08 Jan

h = subplot(X, Y, (x-1)*Y + y);
if nargout>0
    varargout{1} = h;
end
