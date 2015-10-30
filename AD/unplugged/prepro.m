files={'VPhbn','VPis','VPjak','VPlg','VPlh','VPnah','VPnaj'};
sub1 = load(['/home/hidai2/eeglab/plugins/AD/unplugged/',files{1},'_SSAEP_data_epoched.mat']);
x = permute(sub1.data.x,[2,1,3]); % (pnts,nbchan,trials) --> (nbchan,pnts,trials);
save(['/home/hidai2/eeglab/plugins/AD/unplugged/',files{i},'.mat'],'x');
for i=2:3
    subi = load(['/home/hidai2/eeglab/plugins/AD/unplugged/',files{i},'_SSAEP_data_epoched.mat']);
    [~,shuffle_idx] = match_ranks(sub1.data.z,subi.data.z);
    x = subi.data.x(:,:,shuffle_idx);
    x = permute(x,[2,1,3]); % (pnts,nbchan,trials) --> (nbchan,pnts,trials);
    save(['/home/hidai2/eeglab/plugins/AD/unplugged/',files{i},'.mat'],'x');    
end
