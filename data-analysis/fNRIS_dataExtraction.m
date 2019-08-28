% fNIRs 101
clc; clear all;
folder=('G:\fnirs_data\Nirxdata\EventAnalysis');
files = dir (folder);
raw = nirs.io.loadDirectory(folder);
Fs=2;


data_cond11_run=[];
%%
for z=1: size(raw,1)
    
    data_cond11=[];
    
    
    data = raw(z);
    j = nirs.modules.RemoveStimless( );
    j = nirs.modules.Resample( j );
    j.Fs = Fs;
    j = nirs.modules.OpticalDensity( j );
    j = nirs.modules.BeerLambertLaw( j );
    hb = j.run( data);
    
    
    %% Trigger Analysis
    
    for i=1:hb.stimulus.count
        verify11(i) = (strcmp(hb.stimulus.keys{i}, 'stim_channel11'));
        verify21(i) = (strcmp(hb.stimulus.keys{i}, 'stim_channel21'));
        verify10(i) = (strcmp(hb.stimulus.keys{i}, 'stim_channel10'));
        verify20(i) = (strcmp(hb.stimulus.keys{i}, 'stim_channel20'));
    end
    index10=find(verify10);
    index11=find(verify11);
    index20=find(verify20);
    index21=find(verify21);
    
    %% Transitions
    PreStim =2*Fs; % TimePoint
    PosStim =6*Fs;
    
    
    try
        %condition 11
        for i=1: size (hb.stimulus.values{index11}.onset,1)
            pre_cond11 = round(hb.stimulus.values{index11}.onset(i)*Fs -PreStim);
            pos_cond11 = round(hb.stimulus.values{index11}.onset(i)*Fs + PosStim);
            data_cond11(i,:,:) = hb.data( [pre_cond11:pos_cond11],:);
        end
%         %condition 21
%         for i=1: size (hb.stimulus.values{index21}.onset,1)
%             pre_cond21 = round(hb.stimulus.values{index21}.onset(i)*Fs -PreStim);
%             pos_cond21 = round(hb.stimulus.values{index21}.onset(i)*Fs + PosStim);
%             data_cond21{i} = hb.data( [pre_cond21:pos_cond21],:);
%         end

    %concatenate data per run
    for e=1:numel(data_cond11)
        data_cond11_run{end+1}= data_cond11(e,:,:);
    end
    
    
%     data_cond21_run{z}= data_cond21;
    
    %% Stable conditions
    
    %         PreStim =1*Fs; % TimePoint
    %         PosStim =8*Fs;
    %
    %         %condition 10
    %         for i=1: size (hb.stimulus.values{index10}.onset,1)
    %
    %             pre_cond10 = round(hb.stimulus.values{index10}.onset(i)*Fs -PreStim);
    %             pos_cond10 = round(hb.stimulus.values{index10}.onset(i)*Fs + PosStim);
    %             data_cond10{i} = hb.data( [pre_cond10:pos_cond10],:);
    %
    %         end
    %
    %         %condition 20
    %         for i=1: size (hb.stimulus.values{index20}.onset,1)
    %
    %             pre_cond20 = round(hb.stimulus.values{index20}.onset(i)*Fs -PreStim);
    %             pos_cond20 = round(hb.stimulus.values{index20}.onset(i)*Fs + PosStim);
    %             data_cond20{i} = hb.data( [pre_cond20:pos_cond20],:);
    %
    %         end
    %
    %         %concatenate date per run
    %         data_cond10_run{z}= data_cond10;
    %         data_cond20_run{z}= data_cond20;
    
     catch
        disp('Condição não presente na RUN ou fora do tempo')
    end   
end

