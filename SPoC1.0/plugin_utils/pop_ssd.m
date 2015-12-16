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
res = {'10','2',0,'15',0,0,0,'','-1 2'}; % default values
for i=1:length(varargin)
    res{i} = varargin{i}; % fill-in given values
end

% popup window parameters
% -----------------------
if nargin < 4
         
    uilist = { { 'style' 'text' 'string' 'Central frequency (Hz):' } ...
        { 'style' 'edit' 'string'  res{1} } ...
        { 'style' 'text' 'string' 'Filter order (integer scalar):' } ...
        { 'style' 'edit' 'string'  res{2} } ...
        { 'Style', 'checkbox', 'value', res{3}, 'string', ...
        'Dimension reduction'} ...
        { 'style' 'edit' 'string'  res{4} } ...
        { 'Style', 'checkbox', 'value', res{5}, 'string', ...
        'Save filtered data instead of original'} ...
        { 'Style', 'checkbox', 'value', res{6}, 'string', ...
        'Run on all datasets'} };

    uigeom = { [3 1] [3 1] [3 1] 1 1 };
    if ismatrix(EEG.data) % in case of continuous data - ask whether or not to generate epoch_indices
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
        epogeom = { 1 , 1 , [2 1 0.5] [2 1.5]};
        epolist = { { } {'style', 'checkbox', 'string', 'Use events to choose relevant data', 'value', res{7}} ...
              { 'style' 'text'       'string' 'Time-locking event type(s) ([]=all)' } ...
              { 'style' 'edit'       'string' res{8} 'tag' 'events' } ...
              { 'style' 'pushbutton' 'string' '...' 'callback' cbevent } ...
              { 'style' 'text'       'string' 'Epoch limits [start, end] in seconds' } ...
              { 'style' 'edit'       'string' res{9} } };
        uilist = [ uilist , epolist];
        uigeom = [ uigeom , epogeom];
    end
    res = inputgui( 'uilist', uilist, 'geometry', uigeom, 'title', 'SSD - pop_ssd()', 'helpcom', 'pophelp(''pop_ssd'');');
end

    run_on_all = res{6}; % run on all datasets (yes/no)
       
% in case of multiple subjects 

if run_on_all

   res{6} = 0;
   mark = CURRENTSET;
   l = length(ALLEEG);
   for i=1:l
       [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',mod(i+mark-1,l)+1);
       eval(sprintf('[ALLEEG EEG] = pop_ssd(ALLEEG, EEG, CURRENTSET,%s);',vararg2str(res)));       
   end
   warndlg2('Successful SSD for all datasets!','Notice');
   return;
end
 
    fc = str2num(res{1});
    bw = 0.5;
    nbw = 1.8;
    df = 0.2;
    signal_band = 2.^(log2(fc)+bw.*[-0.5,0.5]); % signal bandpass band
    noise_bp_band = 2.^(log2(fc)+nbw.*[-0.5,0.5]); % noise bandpass band
    noise_bs_band = 2.^(log2(fc)+(bw+df).*[-0.5,0.5]); % noise bandstop band
    filter_order = str2num(res{2}); % filter order
    auto_dim_redu = res{3}; % automated dimention reduction (yes/no)
    n_dim_redu = str2num(res{4}); % number of dimention to reduce to
    save_filtered = res{5}; % saving filtered data instead of original (yes/no)
    
 if ismatrix(EEG.data) && res{7}
     
% following code is based on pop_epoch()
    if ~isempty(res{8})
       if strcmpi(res{9}(1),'''')   % If event type appears to be in single-quotes, use comma
                                       % and single-quote as delimiter between event types. toby 2.24.2006
                                       % fixed Arnaud May 2006
                    events = eval( [ '{' res{8} '}' ] );
       else    events = parsetxt( res{8});
       end;
    else events = {};
    end
   lim = eval( [ '[' res{9} ']' ] );
   
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
    X_s = A*X_ssd'; % X_ssd = X_s * W
    if ~ismatrix(EEG.data)
        n = size(X_s,1);
        sz = size(EEG.data); % 1=chan,2=pnts,3=trials
        X_s = reshape(X_s,[n,sz(2),sz(3)]); %(nbchan,pnts*trials) --> (nchan,pnts,trials) 
    end
    EEG.data = X_s;
end

model = struct('SPoC_lambda',num2cell(lambda'));
EEG = SPoC_store_new_weights( EEG , W', eye(EEG.nbchan), 1:EEG.nbchan,'SSD',model);
EEG.icawinv = A;

if nargin < 4
    warndlg2(['Successful SSD for ' EEG.setname '!'],'Notice');
end

if auto_dim_redu
    EEG = pop_subcomp(EEG,(n_dim_redu+1):size(EEG.icaweights,1));
    EEG = pop_editset( EEG, 'setname', [EEG.setname(1:end-3) 'SSD']);
end

[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

return;