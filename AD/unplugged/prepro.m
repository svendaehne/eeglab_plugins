files={'VPhbn','VPis','VPjak','VPlg','VPlh','VPnah','VPnaj'};
sub1 = load(['eeglab/plugins/AD/unplugged/',files{1},'_SSAEP_data_epoched.mat']);
x = permute(sub1.data.x,[2,1,3]); % (pnts,nbchan,trials) --> (nbchan,pnts,trials);
clab = sub1.data.clab;
save(['eeglab/plugins/AD/unplugged/',files{1},'.mat'],'x');
save(['eeglab/plugins/AD/unplugged/',files{1},'.loc'],'clab');
for i=2:3
    subi = load(['eeglab/plugins/AD/unplugged/',files{i},'_SSAEP_data_epoched.mat']);
    [~,shuffle_idx] = match_ranks(sub1.data.z,subi.data.z);
    x = subi.data.x(:,:,shuffle_idx);
    x = permute(x,[2,1,3]); % (pnts,nbchan,trials) --> (nbchan,pnts,trials);    
    clab = subi.data.clab;
    save(['eeglab/plugins/AD/unplugged/',files{i},'.mat'],'x');
    save(['eeglab/plugins/AD/unplugged/',files{i},'.loc'],'clab');
end
