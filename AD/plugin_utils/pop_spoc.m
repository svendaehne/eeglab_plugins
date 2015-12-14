% pop_spoc() - SPoC algorithm. If number of input arguments is less
%         than 2, pop up an interactive query window. Calls spoc().
%
% Usage:
%   >>  OUTEEG = pop_spoc( INEEG );
%
% Inputs:
%   INEEG   - input EEG dataset
%    
% Outputs:
%   OUTEEG  - output dataset
%
% See also: spoc(), pop_ssd(), ssd()
%
% Copyright (C) 2014 Idai Guertel. Adapted from: Arnaud Delorme, Scott
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

function [EEG, com] = pop_spoc( EEG , varargin)

com = '';

% display help if not enough arguments
% ------------------------------------
if nargin < 1
    help spoc;
    return;
end;

continuous = ismatrix(EEG.data);
if continuous
    res = {'z.mat','0','-1 2',''}; % default values
else
    res = {'z.mat','0',num2str([EEG.xmin EEG.xmax]),''}; % default values
end

for i=1:length(varargin)
    res{i} = varargin{i};
end

% popup window parameters
% -----------------------
if nargin < 2
    commandload = [ '[filename, filepath] = uigetfile(''*'', ''Select a text file'');' ...
                    'if filename(1) ~=0,' ...
                    '   set(findobj(''parent'', gcbf, ''tag'', tagtest), ''string'', [ filepath filename ]);' ...
                    'end;' ...
                    'clear filename filepath tagtest;' ];
    uilist = { { 'Style', 'text', 'string', 'Target function file' } ...
         { 'Style', 'pushbutton', 'string', 'Browse', 'callback', [ 'tagtest = ''path'';' commandload ] }...
         { 'Style', 'edit', 'string', res{1}, 'tag',  'path' }, {},...
        { 'style' 'text'       'string' 'Number of bootstrapping iterations (0 = non)' } ...
        { 'style' 'edit'       'string' res{2} } ...
        { } {'style', 'text', 'string', 'Choose relevant data'} ...
        { 'style' 'text'       'string' 'Epoch limits [start, end] in seconds' } ...
        { 'style' 'edit'       'string' res{3} } };

    uigeom = { [3 1] 1 1 [3 1] 1 1 [2 1.5] };
    if continuous % in case of continuous data ask which event is relevant
       cbevent = ['if ~isfield(EEG.event, ''type'')' ...
				   '   errordlg2(''No type field'');' ...
				   'else' ...
                   '   tmpevent = EEG.event;' ...
                   '   if isnumeric(EEG.event(1).type),' ...
				   '        [tmps,tmpstr] = pop_chansel(unique([ tmpevent.type ]));' ...
				   '   else,' ...
                   '        [tmps,tmpstr] = pop_chansel(unique({ tmpevent.type }));' ...
                   '   end;' ...
				   '   if ~isempty(tmps)' ...
				   '       set(findobj(''parent'', gcbf, ''tag'', ''events''), ''string'', tmpstr);' ...
				   '   end;' ...
				   'end;' ...
				   'clear tmps tmpevent tmpv tmpstr tmpfieldnames;' ];
        epogeom = {[2 1 0.5]};
        epolist = { { 'style' 'text'       'string' 'Time-locking event type(s) ([]=all)' } ...
        { 'style' 'edit'       'string' res{4} 'tag' 'events' } ...
        { 'style' 'pushbutton' 'string' '...' 'callback' cbevent } };

        uilist = [ uilist , epolist];
        uigeom = [ uigeom , epogeom];
    end

    res = inputgui( 'uilist', uilist, 'geometry', uigeom, 'title', 'SPoC - pop_spoc()', 'helpcom', 'pophelp(''pop_spoc'');');
end
    z_path = res{1}; % target function file path
    n_bootstrapping_iterations = str2num(res{2});
    lim = eval( [ '[' res{3} ']' ] );

    
X = double(EEG.data);
sampling_freq = EEG.srate;

% reshape to fit spoc()
% ---------------------
% in case of continuous data extract ephocs
if continuous
    if ~isempty(res{4})
       if strcmpi(res{4}(1),'''')   % If event type appears to be in single-quotes, use comma
                                       % and single-quote as delimiter between event types. toby 2.24.2006
                                       % fixed Arnaud May 2006
                    events = eval( [ '{' res{4} '}' ] );
       else    events = parsetxt( res{4});
       end;
    else events = {};
    end    
    tempEEG = EEG;
    tempEEG.data = X;
    tempEEG = pop_epoch(tempEEG,events,lim);
    X = double(tempEEG.data);
% otherwise change size of epochs
else
    real_lim = round(lim*sampling_freq - EEG.xmin*sampling_freq + 1);
    X = X(:,real_lim(1):real_lim(2),:);
end
X = permute(X,[2,1,3]); % (nbchan,pnts,trials) --> (pnts,nbchan,trials)

% target function
matObj = matfile(z_path);
varlist = who(matObj);
z = matObj.(varlist{1});
z = z(:)';

% call spoc function
% ------------------
[W, EEG.icawinv, lambda, p_value, ~, ~, ~] = spoc(X, z,'n_bootstrapping_iterations',n_bootstrapping_iterations);
l = length(lambda);
% calculating and saving results
% ------------------------------
X = permute(X,[2,1,3]); % (pnts,nbchan,trials) --> (nbchan,pnts,trials)
sz = size(X); % 1=chan,2=pnts,3=trials
X = X(:,:)'; % (nbchan,pnts,trials) --> (nbchan,pnts*trials) --> (pnts*trials,nbchan)
X = X*W;
X = reshape(X,[sz(2),sz(3),l]); %(pnts*trials,nbchan) --> (pnts,trials,nchan)
X_var = zeros(sz(3),l);
if (l*sz(2)*sz(3))<=10^6;
  X_var = squeeze(var(X));
else
  for i=1:sz(3)
    X_var(i,:) = squeeze(var(X(:,i,:)));
  end
end
X_var = (log(X_var));

model = struct('AD_lambda',num2cell(lambda'),'SPoC_p_value',num2cell(p_value),'SPoC_signal',mat2cell(X_var,sz(3),ones(1,l)));
EEG = AD_store_new_weights( EEG , W', eye(EEG.nbchan) ,1:EEG.nbchan ,'SPoC',model);
EEG.AD_z = z;

if nargin < 2
    warndlg2(['Successful SPoC for ' EEG.setname '!'],'Notice');
end
     
% return the string command
% -------------------------
com =  sprintf('EEG = pop_spoc(%s,%s);', inputname(1), vararg2str(res));

return;