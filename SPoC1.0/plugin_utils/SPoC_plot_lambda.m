% SPoC_plot_lambda() - plot bar graph of the lambda values corresponding to
% to the eigenvalues of a given decomposition (SSD or SPOC)
%
% Usage:
%   >>  SPoC_plot_lambda(EEG);
%
% Inputs:
%   INEEG   - input EEG dataset
%
% See also: pop_ssd(), ssd(), pop_spoc(), spoc()
%
% Copyright (C) 2015 Idai Guertel.
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

function com = SPoC_plot_lambda(EEG)

tmplocs = EEG.chanlocs;
noloc = isempty(tmplocs) || ~isfield(tmplocs, 'theta') || all(cellfun('isempty', { tmplocs.theta }));
if ~noloc % in case scalp plot is possible
    subplot(2,1,1);
    topoplot(zeros(EEG.nbchan,1),EEG.chanlocs,  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
    title('Click on the bars')
    subplot(2,1,2);
end

% plot bar graph
bar([EEG.dipfit.model.SPoC_lambda]);
xlabel('Component number')
ylabel('Lambda value')

function mouseclick_callback(~,~)
    % changes scalp plot source if a bar was clicked
    switch get(gcf,'SelectionType')
           case 'normal' % Click left mouse button.
               cP = get(gca,'Currentpoint');
               x = round(cP(1,1));
               subplot(2,1,1)
               cla
               topoplot(EEG.icawinv(:,x),EEG.chanlocs);
               title(['C #' int2str(x)])
    end
end
function mouseclick_callback2(~,~)
    %resets scalp plot source if background was clicked 
    switch get(gcf,'SelectionType')
        case 'normal' % Click left mouse button.
subplot(2,1,1)
cla
topoplot(zeros(EEG.nbchan,1),EEG.chanlocs,  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
title('Click on the bars')
    end
end

if ~noloc % in case scalp plot is possible
    set(gca,'ButtonDownFcn', @mouseclick_callback2) % background function
    set(get(gca,'Children'),'ButtonDownFcn', @mouseclick_callback) % bar function
end

com =  sprintf('SPoC_plot_lambda(%s);', inputname(1));

end