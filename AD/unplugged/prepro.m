files={'VPhbn','VPis','VPjak','VPlg','VPlh','VPnah','VPnaj'};
sub1 = load(['eeglab/plugins/AD/unplugged/',files{1},'_SSAEP_data_epoched.mat']);
% x = permute(sub1.data.x,[2,1,3]); % (pnts,nbchan,trials) --> (nbchan,pnts,trials);
clab = sub1.data.clab;
% EEG = pop_importdata('setname',files{1},'data','x','dataformat','matlab','subject',files{1},'srate',250);
n = length(clab);
for j=1:n
    clab(j)
    EEG.chanlocs(j).labels = clab(j);
end
% pop_saveset(EEG);
% 
% for i=2:3
%     subi = load(['eeglab/plugins/AD/unplugged/',files{i},'_SSAEP_data_epoched.mat']);
%     [~,shuffle_idx] = match_ranks(sub1.data.z,subi.data.z);
%     x = subi.data.x(:,:,shuffle_idx);
%     x = permute(x,[2,1,3]); % (pnts,nbchan,trials) --> (nbchan,pnts,trials);    
%     clab = subi.data.clab;
%     EEG = pop_importdata('setname',files{i},'data','x','dataformat','matlab','subject',files{i},'srate',250);
%     n = length(clab);
%     for j=1:n
%         EEG.chanlocs(j).labels = clab(j);
%     end
%     pop_saveset( EEG );
% end
