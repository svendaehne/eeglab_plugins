
function EEG = AD_store_new_weights( EEG , weights, sphere, chansind,AD_type,model)

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
if ~isfield(EEG,'dipfit') || ~isstruct(EEG.dipfit)
    EEG.dipfit = struct;
end
if isfield(EEG.dipfit,'model')
    EEG.dipfit = rmfield(EEG.dipfit,'model');
end
EEG.dipfit.model = model;
EEG.icaweights = weights;
EEG.icasphere = sphere;
EEG.icachansind = chansind;
EEG.AD_type = AD_type;

return;