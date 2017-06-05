function figexp(fileName,width,height,varargin)
%   export matlab figure as png and pdf
%   figexp(fileName,width,height)
%
%ARGS
%   fileName    - filename the fig to export to (WITHOUT extension)
%   width       - width of exported picture, RELATIVE to paper size
%   height      - height, RELATIVE to papersize

%created 06/11/13 Jan
try
   try % try to work on copy of figure to preserve on-screen appearance
      h_fig = copyobj(gcf,0);
   catch ME % if that fails (e.g. for figs with multiple y-axes in a single subplot), fall back to original fig
      warning('could not copy figure - falling back to using original fig')
      h_fig = gcf;
      disp(ME.getReport())
   end
   set(h_fig,'Visible','off','WindowStyle','normal');
   
   allaxes   = findall(h_fig,'type','axes');
   %alltext   = findall(h_fig,'type','text');
   %allfont   = [alltext;allaxes];
   
   set( allaxes,'FontUnits','points','FontSize',10,'FontName','Helvetica');
%    set(h_fig,'Renderer','opengl')
   set(h_fig,'Renderer','painters')
   
   set(h_fig,'PaperUnits','centimeters');
   papersize=get(h_fig,'PaperSize');
   width=width*papersize(1) ;      % empty width stays empty this way
   height=height*papersize(2);      % idem
   
   set(h_fig,'PaperPositionMode','manual');
   set(h_fig,'PaperPosition',[0 0 width height]);
   
   if nargin>3 && varargin{1}==0
      save_fig(fileName, 'png');
   else
      save_fig(fileName, 'pdf');
   end
catch ME
   disp(ME.getReport())
end
close(h_fig)
delete(h_fig)
clear h_fig


