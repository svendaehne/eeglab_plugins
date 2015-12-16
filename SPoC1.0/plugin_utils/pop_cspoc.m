% pop_cspoc() - cSPoC algorithm. If number of input arguments is less
%         than 2, pop up an interactive query window. Calls cspoc().
%
% Usage:
%   >>  [OUTALLEEG, OUTEEG] = pop_cspoc( INALLEEG , EEG, CURRENTSET);
%
% Inputs:
%   INALLEEG   - input ALLEEG datasets
%    
% Outputs:
%   OUTALLEEG  - output datasets
%
% See also: cspoc(), pop_spoc(), spoc(), pop_ssd(), ssd()
%
% Copyright (C) 2015 Idai Guertel. Adapted from: Arnaud Delorme, Scott
% Makeig.
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

function [ALLEEG, EEG, com] = pop_cspoc( ALLEEG , EEG, CURRENTSET, varargin)

com = '';

% display help if not enough arguments
% ------------------------------------
if nargin < 3
    help cspoc;
    return;
end;

res = {'1','1',0,0,'10','200','1'}; % default values

for i=1:length(varargin)
    res{i} = varargin{i};
end

% popup window parameters
% -----------------------
if nargin < 4

    uilist = { { 'Style', 'text', 'string', 'Envelope correlations' }, ...
         { 'Style', 'listbox', 'string', 'Maximize|Minimize' } ...
         { 'style' 'text' 'string' 'Number of components sets to be extracted:' } ...
         { 'style' 'edit' 'string'  res{2} } ...
         { 'Style', 'checkbox', 'value', res{3}, 'string', 'Use log'} ...
         { 'Style', 'checkbox', 'value', res{4}, 'string', 'Average over epochs'} ...
         { 'style' 'text' 'string' 'Number of re-starts per component pair:' } ...
         { 'style' 'edit' 'string'  res{5} } ...
         { 'style' 'text' 'string' 'Maximum number of optimizer iterations:' } ...
         { 'style' 'edit' 'string'  res{6} } ...
         { 'style' 'text' 'string' 'Verbose:' } ...
         { 'style' 'edit' 'string'  res{7} } };

    uigeom = { [3 1] [3 1] [] [1] [1] [] [3 1] [3 1] [3 1] };

    res = inputgui( 'uilist', uilist, 'geometry', uigeom, 'title', 'cSPoC - pop_cspoc()', 'helpcom', 'pophelp(''pop_cspoc'');');
    res{1} = 3-2*res{1}; %transformation: (1,2) -> (1,-1)
end

% adjust data to cspoc expected format
l=length(ALLEEG);
for i=1:l
    X{i} = permute(ALLEEG(i).data,[2,1,3]); % (nbchan,pnts,trials) --> (pnts,nbchan,trials)
end

[W, A, r_values, all_r_values] = cspoc(X, res{1},'n_component_sets',str2num(res{2})...
    ,'use_log', res{3},'average_over_epochs',res{4}, 'n_repeats',str2num(res{5})...
    ,'maxIter',str2num(res{6}),'verbose',str2num(res{7}));

for i=1:l
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',i);
    model = struct('cSPoC_r_value',r_values,'cSPoC_all_r_values',all_r_values);
    EEG = SPoC_store_new_weights( EEG , W{i}', eye(EEG.nbchan), 1:EEG.nbchan,'cSPoC',model);
    EEG.icawinv = A{i};
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);    
end

if nargin < 4
    warndlg2(['Successful cSPoC!'],'Notice');
end

% return the string command
% -------------------------

com =  sprintf('[ALLEEG, EEG] = pop_cspoc(%s,%s,%s,%s);', inputname(1),inputname(2),inputname(3), vararg2str(res));

return;