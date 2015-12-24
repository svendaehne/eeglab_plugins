% cSPoC_plot_result() - plot cSPoC results using eegplot().
%
% Usage:
%   >>  cSPoC_plot_result(EEG);
%
% Inputs:
%   INEEG   - cSPoC_plot_result
%
% See also: pop_cspoc(), cspoc(), eegplot()
%
% Copyright (C) 2015 Idai Guertel. Adapted from: Arnaud Delorme, Scott
% Makeig
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

function com = cSPoC_plot_result(ALLEEG)

options = strrep(num2str(1:size(ALLEEG(1).icaweights,1)),'  ','|');
uilist = { { 'Style', 'text', 'string', 'component set number:' }, ...
         { 'Style', 'popupmenu', 'string', options } };
     
res = inputgui( 'uilist', uilist, 'geometry', {[3 1] [] []}, 'title', 'cSPoC_plot_result()', 'helpcom', 'pophelp(''cSPoC_plot_result'');');
if length(res) == 0 return; end;

dim = size(ALLEEG(1).data);
dim(1) = length(ALLEEG);
data = zeros(dim);
for i=1:length(ALLEEG)
    data(i,:,:) = eeg_getdatact(ALLEEG(i), 'component', res{1});
end

eegplot(data);

com =  sprintf('cSPoC_plot_result(%s);', inputname(1));

end