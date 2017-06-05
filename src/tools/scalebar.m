function varargout =  scalebar(x,y,len,txt,fs)
% scalebar(x,y,len,txt,fs)

hl = line([x x+len],[y y],'linewidth',1.5,'color','k');
text(x+len/2,y-0.02*range(ylim),txt,'verticalalignment','top',...
    'horizontalalignment','center','fontsize',fs)
 
 set(get(get(hl,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
 if nargout>0
    varargout{1} = hl;
 end
