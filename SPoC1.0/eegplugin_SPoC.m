% eegplugin_SPoC() - EEGLAB plugin for running SSD SPoC and cSPoC algorithms on EEG data.
%
% Usage:
%   >> eegplugin_SPoC(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
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

function vers = eegplugin_SPoC(fig, trystrs, catchstrs)
    
    vers = 'SPoC_1.0';
    if nargin < 3
        error('eegplugin_SPoC requires 3 arguments');
    end;
    
    % add folder to path
    % -----------------------
    p = which('eegplugin_SPoC');
    p = p(1:findstr(p,'eegplugin_SPoC.m')-1);
    addpath(genpath(p));
    
    % find tools menu
    % ---------------
    toolsmenu = findobj(fig, 'tag', 'tools'); 
    plotmenu = findobj(fig, 'tag', 'plot'); 
    
    % menu callback commands
    % ---------------------
   
    cmd_check_lambda = ['if(~isfield(EEG,''SPoC_type'')|isempty(EEG.SPoC_type)|((~strcmp(EEG.SPoC_type,''SPoC''))&(~strcmp(EEG.SPoC_type,''SSD'')))) ' ...
        'errordlg2(sprintf(''Error: no SSD/SPoC decomposition has beed performed.\n\nUse "Tools > SPoC > Run" first.''), ''Error''); '...
        'return; end; ']; % makes sure that a SSD or SPoC were used.
    cmd_check_SPoC = ['if(~isfield(EEG,''SPoC_type'')|~strcmp(EEG.SPoC_type,''SPoC'')) ' ...
        'errordlg2(sprintf(''Error: no SPoC decomposition has beed performed.\n\nUse "Tools > SPoC > Run SPoC" first.''), ''Error''); '...
        'return; end; ']; % makes sure that SPoC decomposition has beed performed.
    cmd_check_cSPoC = ['if(~isfield(EEG,''SPoC_type'')|~strcmp(EEG.SPoC_type,''cSPoC'')) ' ...
        'errordlg2(sprintf(''Error: no cSPoC decomposition has beed performed.\n\nUse "Tools > SPoC > Run cSPoC" first.''), ''Error''); '...
        'return; end; ']; % makes sure that cSPoC decomposition has beed performed.

    cmd_ssd = [trystrs.no_check '[ALLEEG EEG LASTCOM] = pop_ssd( ALLEEG, EEG, CURRENTSET); '  catchstrs.add_to_hist]; % calls ssd
    cmd_spoc = [trystrs.no_check '[EEG LASTCOM] = pop_spoc( EEG); ' catchstrs.store_and_hist]; % calls spoc
    cmd_cspoc = [trystrs.no_check '[ALLEEG EEG LASTCOM] = pop_cspoc( ALLEEG, EEG, CURRENTSET); ' catchstrs.add_to_hist]; % calls cspoc
    
    cmd_lambda = [trystrs.no_check cmd_check_lambda 'LASTCOM = SPoC_plot_lambda(EEG); ' catchstrs.add_to_hist]; % calls the lambda plotting function.
    cmd_spoc_result = [trystrs.no_check cmd_check_SPoC 'LASTCOM = SPoC_plot_result(EEG); ' catchstrs.add_to_hist]; % calls the lambda plotting function.
    cmd_cspoc_result = [trystrs.no_check cmd_check_cSPoC 'LASTCOM = cSPoC_plot_result(ALLEEG); ' catchstrs.add_to_hist]; % calls the lambda plotting function.
    
    % create menus
    % ------------
    toolssubmenu = uimenu( toolsmenu, 'label', 'SPoC', 'separator', 'on');
    plotsubmenu = uimenu( plotmenu, 'label', 'SPoC', 'separator', 'on');
    uimenu( toolssubmenu, 'label', 'Run SSD', 'callback', cmd_ssd);
    uimenu( toolssubmenu, 'label', 'Run SPoC', 'callback', cmd_spoc);
    uimenu( toolssubmenu, 'label', 'Run cSPoC', 'callback', cmd_cspoc);
    
%     uimenu( toolssubmenu, 'label', 'Remove somponents', 'callback', cmd_subcomp);

    uimenu( plotsubmenu, 'label', 'Lambda spectrum', 'callback', cmd_lambda); %, 'userdata', 'chanloc:on'
    uimenu( plotsubmenu, 'label', 'SPoC results', 'callback', cmd_spoc_result);
    uimenu( plotsubmenu, 'label', 'cSPoC results', 'callback', cmd_cspoc_result);
