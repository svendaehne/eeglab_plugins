% eegplugin_AD() - EEGLAB plugin for running SSD SPoC and cSPoC algorithms on EEG data.
%
% Usage:
%   >> eegplugin_AD(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
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

function vers = eegplugin_AD(fig, trystrs, catchstrs)
    
    vers = 'AD_1.0';
    if nargin < 3
        error('eegplugin_AD requires 3 arguments');
    end;
    
    % add folder to path
    % -----------------------
    p = which('eegplugin_AD');
    p = p(1:findstr(p,'eegplugin_AD.m')-1);
    addpath(genpath(p));
    
    % find tools menu
    % ---------------
    toolsmenu = findobj(fig, 'tag', 'tools'); 
    plotmenu = findobj(fig, 'tag', 'plot'); 
    
    % menu callback commands
    % ---------------------
   
    cmd_check_AD = ['if(~isfield(EEG,''AD_type'')|isempty(EEG.AD_type)) ' ...
        'errordlg2(sprintf(''Error: no advanced decomposition has beed performed.\n\nUse "Tools > Advanced Decompositions > Run" first.''), ''Error''); '...
        'return; end; ']; % makes sure that an 'Advanced decomposition' exists.
    cmd_check_SPoC = ['if(~isfield(EEG,''AD_type'')|~strcmp(EEG.AD_type,''SPoC'')) ' ...
        'errordlg2(sprintf(''Error: no SPoC decomposition has beed performed.\n\nUse "Tools > Advanced Decompositions > Run SPoC" first.''), ''Error''); '...
        'return; end; ']; % makes sure that an 'Advanced decomposition' exists.
%     cmd_over_ica = ['tempEEG = EEG; ' ...
%         'tempEEG.icaact = [];' ...
%         'tempEEG.icawinv = EEG.AD_A; ' ...
%         'tempEEG.icaweights = EEG.AD_WT; ' ...
%         'tempEEG.icasphere = eye(EEG.nbchan); ' ...
%         %'tempEEG.dipfit.model = EEG.AD_lambda; ' ...
%         'tempEEG.icachansind = 1:EEG.nbchan; '];
%     cmd_back = ['EEG.data = tempEEG.data; ' ...
%         'EEG.AD_A = tempEEG.icawinv; ' ...
%         'EEG.AD_WT = tempEEG.icaweights; ' ...
%         'EEG.AD_lambda = tempEEG.dipfit.model; ' ...
%         'EEG.setname = [ tempEEG.setname(1:(numel(tempEEG.setname)-3)) tempEEG.AD_type]; '];

    cmd_ssd = [trystrs.no_check '[EEG LASTCOM] = pop_ssd( EEG); '  catchstrs.store_and_hist]; % calls ssd
    cmd_spoc = [trystrs.no_check '[EEG LASTCOM] = pop_spoc( EEG); ' catchstrs.store_and_hist]; % calls spoc
    cmd_cspoc = [trystrs.no_check '[ALLEEG LASTCOM] = pop_cspoc( ALLEEG); ' catchstrs.store_and_hist]; % calls cspoc
    
%     cmd_subcomp = [trystrs.no_check cmd_check_AD cmd_over_ica '[tempEEG LASTCOM] = pop_subcomp( tempEEG); ' cmd_back catchstrs.new_and_hist];

    cmd_lambda = [trystrs.no_check cmd_check_AD 'LASTCOM = AD_plot_lambda(EEG); ' catchstrs.add_to_hist]; % calls the lambda plotting function.
    cmd_result = [trystrs.no_check cmd_check_SPoC 'LASTCOM = SPoC_plot_result(EEG); ' catchstrs.add_to_hist]; % calls the lambda plotting function.
    
%     cmd_maps = [trystrs.check_chanlocs cmd_check_AD cmd_over_ica 'LASTCOM = pop_topoplot( tempEEG, 0); ' 'clearvars tempEEG; ' catchstrs.add_to_hist];
%     cmd_activation = [trystrs.no_check cmd_check_AD cmd_over_ica 'LASTCOM = pop_eegplot( tempEEG, 0, 1, 1); ' 'clearvars tempEEG; ' catchstrs.add_to_hist];
%     cmd_spectra = [trystrs.check_chanlocs cmd_check_AD cmd_over_ica 'LASTCOM = pop_spectopo( tempEEG, 0); ' 'clearvars tempEEG; ' catchstrs.add_to_hist];
%     cmd_prop = [trystrs.no_check cmd_check_AD cmd_over_ica 'LASTCOM = pop_prop(tempEEG,0); ' 'clearvars tempEEG; ' catchstrs.add_to_hist];
%     cmd_timef = [trystrs.no_check cmd_check_AD cmd_over_ica 'LASTCOM = pop_newtimef(tempEEG,0); ' 'clearvars tempEEG; ' catchstrs.add_to_hist];
%     cmd_crossf = [trystrs.no_check cmd_check_AD cmd_over_ica 'LASTCOM = pop_newcrossf(tempEEG,0); ' 'clearvars tempEEG; ' catchstrs.add_to_hist];
    
    % create menus
    % ------------
    toolssubmenu = uimenu( toolsmenu, 'label', 'Advanced Decompositions', 'separator', 'on');
    plotsubmenu = uimenu( plotmenu, 'label', 'Advanced Decompositions', 'separator', 'on');
    uimenu( toolssubmenu, 'label', 'Run SSD', 'callback', cmd_ssd);
    uimenu( toolssubmenu, 'label', 'Run SPoC', 'callback', cmd_spoc);
    uimenu( toolssubmenu, 'label', 'Run cSPoC', 'callback', cmd_cspoc);
    
%     uimenu( toolssubmenu, 'label', 'Remove somponents', 'callback', cmd_subcomp);

    uimenu( plotsubmenu, 'label', 'Lambda spectrum', 'callback', cmd_lambda); %, 'userdata', 'chanloc:on'
    uimenu( plotsubmenu, 'label', 'SPoC results', 'callback', cmd_result);
%     uimenu( plotsubmenu, 'label', 'Component maps', 'callback', cmd_maps); %, 'userdata', 'chanloc:on'
%     uimenu( plotsubmenu, 'label', 'Component activation (scroll)', 'callback', cmd_activation);
%     uimenu( plotsubmenu, 'label', 'Component spectra and maps', 'callback', cmd_spectra);
%     uimenu( plotsubmenu, 'label', 'Component properties', 'callback', cmd_prop);
%     uimenu( plotsubmenu, 'label', 'Component time-frequency (transform)', 'callback', cmd_timef, 'separator', 'on');
%     uimenu( plotsubmenu, 'label', 'Component cross-coherence', 'callback', cmd_crossf);

% % %   ERP functions:
% % %     uimenu( plot_m, 'Label', 'Component ERP image'                    , 'userdata', onepoch, 'CallBack', cb_erpimage2);
% % %     ERPC_m = uimenu( plot_m, 'Label', 'Component ERPs'                , 'userdata', onepoch);
% % %     uimenu( ERPC_m, 'Label', 'With component maps'                    , 'CallBack', cb_envtopo1);
% % %     uimenu( ERPC_m, 'Label', 'With comp. maps (compare)'              , 'CallBack', cb_envtopo2);
% % %     uimenu( ERPC_m, 'Label', 'In rectangular array'                   , 'CallBack', cb_plotdata2);
% % %     uimenu( plot_m, 'Label', 'Sum/Compare comp. ERPs'                 , 'userdata', onepoch, 'CallBack', cb_comperp2);
% % % 
% % % cb_erpimage2   = [ checkepochica 'LASTCOM = pop_erpimage(EEG, 0, eegh(''find'',''pop_erpimage(EEG,0''));' e_hist];
% % % cb_envtopo1    = [ checkica      'LASTCOM = pop_envtopo(EEG);'            e_hist];
% % % cb_envtopo2    = [ checkica      'if length(ALLEEG) == 1, error(''Need at least 2 datasets''); end; LASTCOM = pop_envtopo(ALLEEG);' e_hist];
% % % cb_plotdata2   = [ checkepochica '[tmpeeg LASTCOM] = pop_plotdata(EEG, 0); clear tmpeeg;' e_hist];
% % % cb_comperp2    = [ checkepochica 'LASTCOM = pop_comperp(ALLEEG, 0);'      e_hist];