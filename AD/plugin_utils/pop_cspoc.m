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

res = {'1'}; % default values

for i=1:length(varargin)
    res{i} = varargin{i};
end

% popup window parameters
% -----------------------
if nargin < 4

    uilist = { { 'Style', 'text', 'string', 'envelope correlations' }, ...
         { 'Style', 'listbox', 'string', 'Maximize|Minimize' } };

    uigeom = { [1 1] };

    res = inputgui( 'uilist', uilist, 'geometry', uigeom, 'title', 'cSPoC - pop_cspoc()', 'helpcom', 'pophelp(''pop_cspoc'');');
    res{1} = 3-2*res{1}; %transformation: (1,2) -> (1,-1)
end

% adjust data to cspoc expected format
l=length(ALLEEG);
for i=1:l
    X{i} = permute(ALLEEG(i).data,[2,1,3]); % (nbchan,pnts,trials) --> (pnts,nbchan,trials)
end

[W, A, r_values, all_r_values] = cspoc(X, res{1});

% l = length(lambda);
% % calculating and saving results
% % ------------------------------
% X = permute(X,[2,1,3]); % (pnts,nbchan,trials) --> (nbchan,pnts,trials)
% sz = size(X); % 1=chan,2=pnts,3=trials
% X = X(:,:)'; % (nbchan,pnts,trials) --> (nbchan,pnts*trials) --> (pnts*trials,nbchan)
% X = X*W;
% X = reshape(X,[sz(2),sz(3),l]); %(pnts*trials,nbchan) --> (pnts,trials,nchan)
% X_var = zeros(sz(3),l);
% if (l*sz(2)*sz(3))<=10^6;
%   X_var = squeeze(var(X));
% else
%   for i=1:sz(3)
%     X_var(i,:) = squeeze(var(X(:,i,:)));
%   end
% end
% X_var = (log(X_var));
% if ~isfield(EEG,'dipfit') || ~isstruct(EEG.dipfit)
%     EEG.dipfit = struct;
% end
% if isfield(EEG.dipfit,'model')
%     EEG.dipfit = rmfield(EEG.dipfit,'model');
% end
% EEG.dipfit.model = struct('AD_lambda',num2cell(lambda'),'AD_p_value',num2cell(p_value),'AD_spoc_signal',mat2cell(X_var,sz(3),ones(1,l)));
for i=1:l
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',i);
    EEG.icaweights = W{i}';
    EEG.icawinv = A{i};
    EEG.icasphere = eye(EEG.nbchan);
    EEG.icachansind = 1:EEG.nbchan;
    EEG.AD_type = 'cSPoC';
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);    
end

warndlg2('Successful cSPoC !','');
     
% return the string command
% -------------------------

com =  sprintf('[ALLEEG, EEG] = pop_cspoc(%s,%s,%s,%s);', inputname(1),inputname(2),inputname(3), vararg2str(res));

return;