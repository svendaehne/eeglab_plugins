% SPoC_plot_result() - plot 
%
% Usage:
%   >>  SPoC_plot_result(EEG);
%
% Inputs:
%   INEEG   - SPoC_plot_result
%
% See also: pop_spoc(), spoc()
%
% Copyright (C) 2014 Idai Guertel
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function com = SPoC_plot_result(EEG)
p = [EEG.dipfit.model.SPoC_p_value];
spoc_signal = [EEG.dipfit.model.SPoC_signal];
z = zscore(EEG.SPoC_z');
x = spoc_signal(:,1);
x = zscore(x);
co = corr(z,x);
x = x*sign(co);

plot(z,'k.-')
title('SPoC component performance')
xlabel({'Trial number';sprintf('SPoC Component 1 ; Correlation = %g ; p value = %g',co,p(1))})
hold on
h = plot(x,'.-');
legend('Normalized target function','Signal log-power')
hold off
uicontrol('Style', 'popup',...
       'String', num2cell(1:size(spoc_signal,2)),...
       'Position', [5 0 40 25],...
       'Callback', @popup_Callback);

function popup_Callback(hObject, ~)
    i = get(hObject,'Value');
    xi = spoc_signal(:,i);
    xi = zscore(xi);
    coi = corr(z,xi);
    xi = xi*sign(coi);
    set(h,'YData',xi)
    xlabel({'Trial number';sprintf('SPoC Component %d ; correlation = %g ; p value = %g',i,coi,p(i))})
end

com =  sprintf('SPoC_plot_result(%s);', inputname(1));

end