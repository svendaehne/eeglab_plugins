% pop_ssd() - SSD algorithm. If number of input arguments is less
%         than 2, pop up an interactive query window. Calls ssd().
%
% Usage:
%   >>  OUTEEG = pop_ssd( INEEG );
%
% Inputs:
%   INEEG   - input EEG dataset
%    
% Outputs:
%   OUTEEG  - output dataset
%
% See also: ssd(), pop_spoc(), spoc()
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

function [EEG, com] = pop_ssd( EEG , varargin)

com = '';           

% display help if not enough arguments
% ------------------------------------
if nargin < 1
    help pop_ssd;
    return;
end;
          
epoch_indices = [];
res = {'10 12','5 16','7 13','2',0,'','-1 2'}; % default values
for i=1:length(varargin)
    res{i} = varargin{i}; % fill-in given values
end

% popup window parameters
% -----------------------
if nargin < 4
          
    uilist = { { 'style' 'text' 'string' 'Signal bandpass band ([min max] in Hz):' } ...
        { 'style' 'edit' 'string'  res{1} } ...
        { 'style' 'text' 'string' 'Noise bandpass band ([min max] in Hz):' } ...
        { 'style' 'edit' 'string'  res{2} } ...
        { 'style' 'text' 'string' 'Noise bandstop band ([min max] in Hz):' } ...
        { 'style' 'edit' 'string'  res{3} } ...
        { 'style' 'text' 'string' 'filter order (integer scalar):' } ...
        { 'style' 'edit' 'string'  res{4} } };

    uigeom = { [3 1] [3 1] [3 1] [3 1] };
    if ismatrix(EEG.data) % in case of continuous data - ask whether to generate epoch_indices
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
        epogeom = { 1 , 1 , [2 1 0.5] [2 1 0.5]};
        epolist = { { } {'style', 'checkbox', 'string', 'Use events to choose relevant data', 'value', res{5}} ...
              { 'style' 'text'       'string' 'Time-locking event type(s) ([]=all)' } ...
              { 'style' 'edit'       'string' res{6} 'tag' 'events' } ...
              { 'style' 'pushbutton' 'string' '...' 'callback' cbevent } ...
              { 'style' 'text'       'string' 'Epoch limits [start, end] in seconds' } ...
              { 'style' 'edit'       'string' res{7} } { } };
        uilist = [ uilist , epolist];
        uigeom = [ uigeom , epogeom];
    end
    res = inputgui( 'uilist', uilist, 'geometry', uigeom, 'title', 'SSD - pop_ssd()', 'helpcom', 'pophelp(''pop_ssd'');');
end

    signal_band = str2num(res{1}); % signal bandpass band
    noise_bp_band = str2num(res{2}); % noise bandpass band
    noise_bs_band = str2num(res{3}); % noise bandstop band
    filter_order = str2num(res{4}); % filter order
    
 if ismatrix(EEG.data) && res{5}
     
% following code is based on pop_epoch()
    if ~isempty(res{6})
       if strcmpi(res{6}(1),'''')   % If event type appears to be in single-quotes, use comma
                                       % and single-quote as delimiter between event types. toby 2.24.2006
                                       % fixed Arnaud May 2006
                    events = eval( [ '{' res{6} '}' ] );
       else    events = parsetxt( res{6});
       end;
    else events = {};
    end
   lim = eval( [ '[' res{7} ']' ] );
   
tmpevent = EEG.event;
tmpeventlatency = [ tmpevent(:).latency ];
[tmpeventlatency, Itmp] = sort(tmpeventlatency);
EEG.event = EEG.event(Itmp);  % sort by ascending time 
Ievent = 1:length(EEG.event);

if ~isempty( events )
        % select the events for epoching
        % ------------------------------
        Ieventtmp = [];
        tmpevent = EEG.event;
        tmpeventtype  = { tmpevent.type };
        if iscell(events)
            if isstr(EEG.event(1).type)
                for index2 = 1:length( events )
                    tmpevent = events{index2};
                    if ~isstr( tmpevent ), tmpevent = num2str( tmpevent ); end;
                    Ieventtmp = [ Ieventtmp ; strmatch(tmpevent, tmpeventtype, 'exact') ];
                end;
            else
                for index2 = 1:length( events )
                    tmpevent = events{index2};
                    if isstr( tmpevent ),tmpevent = str2num( tmpevent ); end;
                    if isempty( tmpevent ), error('pop_epoch(): string entered in a numeric field'); end;
                    Ieventtmp = [ Ieventtmp find(tmpevent == [ tmpeventtype{:} ]) ];
                end;
            end;
        else
            error('pop_epoch(): multiple event types must be entered as {''a'', ''cell'', ''array''}'); return;
        end;
        Ievent = sort(intersect(Ievent, Ieventtmp));
    end

    % select event latencies
    %------------------------------------
    Ievent = sort(Ievent);
    alllatencies = tmpeventlatency(Ievent);
    % % % 

    epoch_indices = repmat([lim(1) lim(2)]*EEG.srate,numel(alllatencies),1) + repmat(alllatencies,2,1)';
    epoch_indices = int32(epoch_indices);
    epoch_indices(epoch_indices<1) = 1;
    max = size(EEG.data,2);
    epoch_indices(epoch_indices>max) = max;
end

% Store and then remove current EEG weights and sphere
% ----------------------------------------------------
% following code based on pop_runica()

fprintf('\n');
if ~isempty(EEG.icaweights)
    fprintf('Saving current decomposition in "EEG.etc.oldweights" (etc.).\n');
    if(~isfield(EEG,'AD_type')||isempty(EEG.AD_type))
        EEG.AD_type = 'ICA';
    end
    if ~isfield(EEG,'etc'), EEG.etc = []; end;
    if ~isfield(EEG.etc,'oldweights')
        EEG.etc.oldweights = {};
        EEG.etc.oldsphere = {};
        EEG.etc.oldchansind = {};
        EEG.etc.oldtype = {};
    end;
    tmpoldweights  = EEG.etc.oldweights;
    tmpoldsphere   = EEG.etc.oldsphere;
    tmpoldchansind = EEG.etc.oldchansind;
    tmpoldtype     = EEG.etc.oldtype;
    EEG.etc.oldweights = { EEG.icaweights    tmpoldweights{:} };
    EEG.etc.oldsphere  = { EEG.icasphere     tmpoldsphere{:}  };
    EEG.etc.oldchansind  = { EEG.icachansind tmpoldchansind{:}  };
    EEG.etc.oldtype = {EEG.AD_type tmpoldtype{:}    };
    fprintf('               Decomposition saved as entry %d.\n',length(EEG.etc.oldweights));
end
EEG.icaweights = [];
EEG.icasphere  = [];
EEG.icawinv    = [];
EEG.icaact     = [];

% call ssd function
% -----------------
X = double(EEG.data(:,:)'); %change shape to fit ssd() in any case. data --> (nbchan,pnts*trials) --> (pnts*trials,nbchan)
freq = zeros(3,2);
freq(1,:) = signal_band; % signal bandpass band
freq(2,:) = noise_bp_band; % noise bandpass band
freq(3,:) = noise_bs_band; % noise bandstop band
sampling_freq = EEG.srate;
[W, EEG.icawinv, lambda, ~, ~] = ssd(X, freq, sampling_freq,filter_order,epoch_indices);

if ~isfield(EEG,'dipfit') || ~isstruct(EEG.dipfit)
    EEG.dipfit = struct;
end
if isfield(EEG.dipfit,'model')
    EEG.dipfit = rmfield(EEG.dipfit,'model');
end
EEG.dipfit.model = struct('AD_lambda',num2cell(lambda'));

EEG.icaweights = W';
EEG.icasphere = eye(EEG.nbchan);
EEG.icachansind = 1:EEG.nbchan;
EEG.AD_type = 'SSD';
warndlg2('Successful SSD !','');
     
% return the string command
% -------------------------
com =  sprintf('EEG = pop_ssd(%s,%s);', inputname(1), vararg2str(res));

return;