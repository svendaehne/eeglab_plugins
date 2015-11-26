% pop_ssd() - SSD algorithm. If number of input arguments is less
%         than 2, pop up an interactive query window. Calls ssd().
%
% Usage:
%   >> [ALLEEG EEG] = pop_newset( ALLEEG, EEG, CURRENTSET )
%
% Inputs and outputs:
%   ALLEEG     - array of EEG dataset structures
%   EEG        - current dataset structure or structure array
%   CURRENTSET - index(s) of the current EEG dataset(s) in ALLEEG
%
% See also: ssd(), pop_spoc(), spoc()
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

function [ALLEEG, EEG, com] = pop_ssd( ALLEEG, EEG , CURRENTSET, varargin)

com = '';           

% display help if not enough arguments
% ------------------------------------
if nargin < 3
    help pop_ssd;
    return;
end;
          
epoch_indices = [];
res = {'10 12','5 16','7 13','2',0,'5',0,0,'','-1 2'}; % default values
for i=1:length(varargin)
    res{i} = varargin{i}; % fill-in given values
end

% popup window parameters
% -----------------------
if nargin < 6
          
    uilist = { { 'style' 'text' 'string' 'Signal bandpass band ([min max] in Hz):' } ...
        { 'style' 'edit' 'string'  res{1} } ...
        { 'style' 'text' 'string' 'Noise bandpass band ([min max] in Hz):' } ...
        { 'style' 'edit' 'string'  res{2} } ...
        { 'style' 'text' 'string' 'Noise bandstop band ([min max] in Hz):' } ...
        { 'style' 'edit' 'string'  res{3} } ...
        { 'style' 'text' 'string' 'filter order (integer scalar):' } ...
        { 'style' 'edit' 'string'  res{4} } ...
        { 'Style', 'checkbox', 'value', res{5}, 'string', ...
        'Automatic dimension reduction'} ...
        { 'style' 'edit' 'string'  res{6} } ...
        { 'Style', 'checkbox', 'value', res{7}, 'string', ...
        'Save filtered data instead of original'} ...
        { 'Style', 'checkbox', 'value', res{8}, 'string', ...
        'Run on all datasets'} };

    uigeom = { [3 1] [3 1] [3 1] [3 1] [3 1] [1] [1] };
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
        epolist = { { } {'style', 'checkbox', 'string', 'Use events to choose relevant data', 'value', res{7}} ...
              { 'style' 'text'       'string' 'Time-locking event type(s) ([]=all)' } ...
              { 'style' 'edit'       'string' res{10} 'tag' 'events' } ...
              { 'style' 'pushbutton' 'string' '...' 'callback' cbevent } ...
              { 'style' 'text'       'string' 'Epoch limits [start, end] in seconds' } ...
              { 'style' 'edit'       'string' res{11} } { } };
        uilist = [ uilist , epolist];
        uigeom = [ uigeom , epogeom];
    end
    res = inputgui( 'uilist', uilist, 'geometry', uigeom, 'title', 'SSD - pop_ssd()', 'helpcom', 'pophelp(''pop_ssd'');');
end

    signal_band = str2num(res{1}); % signal bandpass band
    noise_bp_band = str2num(res{2}); % noise bandpass band
    noise_bs_band = str2num(res{3}); % noise bandstop band
    filter_order = str2num(res{4}); % filter order
    auto_dim_redu = res{5}; % automated dimention reduction (yes/no)
    n_dim_redu = str2num(res{6}); % number of dimention to reduce to
    save_filtered = res{7}; % saving filtered data instead of original (yes/no)
    run_on_all = res{8}; % run on all datasets (yes/no)
    
 if ismatrix(EEG.data) && res{9}
     
% following code is based on pop_epoch()
    if ~isempty(res{10})
       if strcmpi(res{11}(1),'''')   % If event type appears to be in single-quotes, use comma
                                       % and single-quote as delimiter between event types. toby 2.24.2006
                                       % fixed Arnaud May 2006
                    events = eval( [ '{' res{10} '}' ] );
       else    events = parsetxt( res{10});
       end;
    else events = {};
    end
   lim = eval( [ '[' res{11} ']' ] );
   
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
 
% return the string command
% -------------------------
   com =  sprintf('[ALLEEG EEG] = pop_ssd(%s,%s,%s,%s);', inputname(1),inputname(2),inputname(3), vararg2str(res));
   
   
% in case of multiple subjects 

if run_on_all

   res{8} = 0;
   mark = CURRENTSET;
   l = length(ALLEEG);
   for i=1:l
       [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',mod(i+mark-1,l)+1);
       eval(sprintf('[ALLEEG EEG] = pop_ssd(ALLEEG, EEG, CURRENTSET,%s);',vararg2str(res)));       
   end
   return;
end

% call ssd function
% -----------------
X = double(EEG.data(:,:)'); %change shape to fit ssd() in any case. data --> (nbchan,pnts*trials) --> (pnts*trials,nbchan)
freq = zeros(3,2);
freq(1,:) = signal_band; % signal bandpass band
freq(2,:) = noise_bp_band; % noise bandpass band
freq(3,:) = noise_bs_band; % noise bandstop band
sampling_freq = EEG.srate;
[W, A, lambda, ~, X_ssd] = ssd(X, freq, sampling_freq,filter_order,epoch_indices);

if save_filtered
    n = length(lambda);
    sz = size(EEG.data); % 1=chan,2=pnts,3=trials
    X_s = A*X_ssd'; % X_ssd = X_s * W
    EEG.data = reshape(X_s,[n,sz(2),sz(3)]); %(nbchan,pnts*trials) --> (nchan,pnts,trials)    
end

model = struct('AD_lambda',num2cell(lambda'));
EEG = AD_store_new_weights( EEG , W', eye(EEG.nbchan), 1:EEG.nbchan,'SSD',model);
EEG.icawinv = A;

fprintf(['\nSuccessful SSD for ' EEG.setname '!\n\n']);

%com='';
if auto_dim_redu
    EEG = pop_subcomp(EEG,(n_dim_redu+1):size(EEG.icaweights,1));
    EEG.setname = [EEG.setname(1:end-3) 'SSD'];
end

[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

return;